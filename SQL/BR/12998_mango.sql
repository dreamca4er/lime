
-- Хранимка для отчета "Выписка из реестра договоров (pdf)"
CREATE OR ALTER PROCEDURE [bi].[sp_UpdateTransferDocumentRegister] as
begin

    if 1=1 return
    -- https://limezaim.atlassian.net/browse/BR-5318
    drop table if exists #Product

    select distinct ProductId
    into #Product
    from Ecc.Notice n
    where n.CreatedOn >= '20181110'
        and n.CreatedOn < '20181111'
        and n.Templateuuid in ('E24DA8BA-06BB-2FF9-B3EB-C46706E108DD', 'E24DD01D-06BB-2FF9-B3FF-C46706E108DD')
        and n.Text is not null

    declare @currentDate date = cast(getdate() as date)

    drop table if exists #doc

    select
        cast(op.AssignDate as date) as AssignDate                   -- дата начала действия     (=дата назначения)
        , cast(op.LastDayWasAssigned as date) as LastDayWasAssigned -- дата окончания действия  (=дата снятия)
        , case 
		    when op.CollectorId = '195B6C8F-389D-4F6E-AF99-85AC8586F129' then 0	-- BR-5284. Манго. Буфер ПС
		    when h.CollectorGroupName = N'Буфер ОСВ'
			    and op.AssignDate = '20181111' 
			    and c.ProductId is not null then 0	-- BR-5318
            when h.CollectorName like N'Буфер%' then 1
            else 0
        end as IsFakeCollector
        , op.CollectorId
	    , op.OverdueStart
        , op.ProductId
        , h.DayCollectorGroupNum as GroupId
    into #doc
    from col.tf_op('19000101', @currentDate) op
    inner join bi.CollectorGroupHistory h on h.CollectorId = op.CollectorId
                                            and h.Date = op.AssignDate
    left join #Product c on c.ProductId = op.ProductId
    option (recompile)
    --where op.ProductId = 149275
    --where op.ProductId = 403421
    --where op.ProductId = 401978
    --where op.ProductId = 341345

    delete #doc 
    where OverdueStart = '20180907'     -- https://limezaim.atlassian.net/browse/BR-5976
            and ProductId = 136959

    drop table if exists #docDate

    create table #docDate (ProductId int, OverdueStart date, AssignDate date, LastDayWasAssigned date)

    -- 1. Убираем кривые переходы в Буфер ТП из "старших групп"
    delete d
    from #doc d
    where d.Groupid = 1
        and exists
        (
            select 1 from #doc d2
            where d2.ProductId = d.ProductId
                and d2.Groupid != 1
                and d2.OverdueStart = d.OverdueStart
                and d2.AssignDate < d.AssignDate
        )
    ;
    
    drop table if exists #FixedDoc
    ;
    
    -- 2. Протягиваем текущее назначение до начала следующего, если в назначениях есть "дыра"
    select
        d.AssignDate
        , case
            when lead(d.AssignDate) 
                    over (partition by d.ProductId, d.OverdueStart order by d.AssignDate) 
                != dateadd(d, 1, d.LastDayWasAssigned)
            then dateadd(d, -1, lead(d.AssignDate) 
                    over (partition by d.ProductId, d.OverdueStart order by d.AssignDate))
            else d.LastDayWasAssigned
        end as LastDayWasAssigned
        , d.IsFakeCollector
        , d.CollectorId
        , d.OverdueStart
        , d.ProductId
        , d.GroupId
    into #FixedDoc
    from #doc d
    ;

    create index IX_FixedDoc_ProductId on #FixedDoc(ProductId)
    ;

    drop table if exists #gc
    ;
    -- Готовим таблицу принадлежности коллектора к ЮЛ
    with col as 
    (
        select
            cgh.Date
            , cgh.CollectorId
            , cgh.CollectorName
            , cgh.DayCollectorGroupNum as Groupid
            , cgh.DayCollectorGroupName as GroupName
            , cle.TransferIsLogged
        from bi.CollectorGroupHistory cgh
        inner join bi.vw_CollectorGroupLegalEntity cle on cle.ItemId = cgh.CollectorId
            and cle.ItemType = 'CollectorId'
            and cgh.Date >= cle.DateFrom
            and cgh.Date < cle.DateTo
        where cgh.DayCollectorGroupNum is not null
    )
    
    select *, lead(TransferIsLogged) over (partition by CollectorId order by Date) as NextTransferIsLogged
    into #gc
    from
    (
        select
            col.Date
            , col.CollectorId
            , col.CollectorName
            , col.Groupid
            , col.GroupName
            , col.TransferIsLogged
        from col
        
        union all
        
        select
            cgh.Date
            , cgh.CollectorId
            , cgh.CollectorName
            , cgh.DayCollectorGroupNum as Groupid
            , cgh.DayCollectorGroupName as GroupName
            , gle.TransferIsLogged
        from bi.CollectorGroupHistory cgh
        inner join bi.vw_CollectorGroupLegalEntity gle on gle.ItemId = cgh.DayCollectorGroupNum
            and gle.ItemType = 'GroupId'
            and cgh.Date >= gle.DateFrom
            and cgh.Date < gle.DateTo
        where cgh.DayCollectorGroupNum is not null
            and not exists
            (
                select 1 from col
                where col.CollectorId = cgh.CollectorId
                    and col.Date = cgh.Date
            )
    ) gc
    ;
    
    create index IX_gc_CollectorId on #gc(CollectorId, Date)
    ;
    
    drop table if exists #un
    ;
    
    with gc as 
    (
        select
            CollectorId
            , min(Date) as TransferStatusStart
            , te.TransferStatusLastDay
            , TransferIsLogged
        from #gc gc
        outer apply
        (
            select min(gc2.Date) as TransferStatusLastDay -- Первая дата, после которой TransferIsLogged сменится
            from #gc gc2
            where gc2.CollectorId = gc.CollectorId
                and (gc2.NextTransferIsLogged != gc.TransferIsLogged or gc2.NextTransferIsLogged is null)
                and gc2.Date >= gc.Date
        ) te
        where gc.TransferIsLogged = 1
        group by 
            CollectorId
            , TransferIsLogged
            , te.TransferStatusLastDay
    )
    -- Рассматриваем разные кейсы, когда коллекторское назначение попадало в интервал отслеживания передач и возвратов ЮЛ
    select *, lead(DateFrom) over (partition by ProductId order by DateFrom) as NextStart
    into #un
    from
    (
        /*
        <--------->         : Период принадлежности кредита к группе в ЮЛ
               <--------->  : Период, в который нужно отслеживать передачи/возвраты должников этому Юл
        */
        select
            d.*
            , gc.TransferStatusStart as DateFrom
            , d.LastDayWasAssigned as DateTo
            , 1 as Type
        from gc 
        inner join #FixedDoc d on d.CollectorId = gc.CollectorId
            and d.AssignDate < gc.TransferStatusStart
            and d.LastDayWasAssigned > gc.TransferStatusStart
            and d.LastDayWasAssigned <= gc.TransferStatusLastDay
        
        
        union
        
        /*
          <---->    : Период принадлежности кредита к группе в ЮЛ
        <---------> : Период, в который нужно отслеживать передачи/возвраты должников этому Юл
        */
        select
            d.*
            , d.AssignDate
            , d.LastDayWasAssigned
            , 2 as Type
        from gc
        inner join #FixedDoc d on d.CollectorId = gc.CollectorId
            and d.AssignDate between gc.TransferStatusStart and gc.TransferStatusLastDay
            and d.LastDayWasAssigned between gc.TransferStatusStart and gc.TransferStatusLastDay
        
        union
        
        /*
                <-----> : Период принадлежности кредита к группе в ЮЛ
        <--------->     : Период, в который нужно отслеживать передачи/возвраты должников этому Юл
        */
        select
            d.*
            , d.AssignDate
            , gc.TransferStatusLastDay
            , 3 as Type
        from gc
        inner join #FixedDoc d on d.CollectorId = gc.CollectorId
            and d.AssignDate >= gc.TransferStatusStart 
            and d.AssignDate <= gc.TransferStatusLastDay
            and d.LastDayWasAssigned > gc.TransferStatusLastDay
        
        union 
    
        /*
          <----->       : Период, в который нужно отслеживать передачи/возвраты должников этому Юл
        <----------->   : Период принадлежности кредита к группе в ЮЛ
        */
        select
            d.*
            , gc.TransferStatusStart
            , gc.TransferStatusLastDay
            , 5 as Type
        from gc
        inner join #FixedDoc d on d.CollectorId = gc.CollectorId
            and gc.TransferStatusStart > d.AssignDate 
            and gc.TransferStatusStart < d.LastDayWasAssigned
            and gc.TransferStatusLastDay > d.AssignDate 
            and gc.TransferStatusLastDay < d.LastDayWasAssigned
    ) un
    ;
    create index IX_un_Productid on #un (Productid)
    ;
    
    -- Схлапываем назначения, берем только вход или выход
    insert  #docDate
    select *
    from
    (
        select
            ProductId
            , OverdueStart
            , min(DateFrom) as AssignDate
            , TransferEnd as LastDayWasAssigned
        from #un un
        outer apply
        (
            select min(DateTo) as TransferEnd
            from #un un2
            where un2.ProductId = un.ProductId
                and un2.OverdueStart = un.OverdueStart
                and un2.DateFrom >= un.DateFrom
                and datediff(d, un2.DateTo, isnull(un2.NextStart, getdate())) > 1 
        ) tf
        where not exists
            (
                select 1 from bi.DocumentRegisterCorrectProduct cc 
                where cc.Productid = un.ProductId 
                    and cc.DocumentRegisterCorrectId = 1    
            )
        group by
            ProductId
            , OverdueStart
            , TransferEnd
    ) a
    ;

    -- https://limezaim.atlassian.net/browse/BR-5318
    insert #docDate (Productid, OverdueStart, AssignDate, LastDayWasAssigned)
    select 
        p.Id as ProductId
        , o.OverdueStart
        , '20181111' as AssignDate
        , '20181111' as LastDayWasAssigned
    from Prd.Product p
    outer apply (
        select top 1 s.StartedOn as OverdueStart, '20181111' as AssignDate, '20181111' as LastDayWasAssigned
        from Prd.vw_statusLog s
        where s.ProductId = p.Id
            and s.StartedOn < '20181110'
        order by s.StartedOn desc
    ) o
    where p.Id in (109066, 123053, 126686, 128586, 132536, 132708, 135754, 137023, 137124, 138191, 139390, 139933, 140690, 140701, 141753, 143969, 144711, 145076, 146423, 147745
		        , 148669, 148743, 149487, 149489, 149896, 150258, 150988, 151216, 151323, 151433, 151725, 151789, 151897, 151931, 152049, 152160, 152173, 152174, 155486)

    -- https://limezaim.atlassian.net/browse/BR-5803
    update #docDate
    set LastDayWasAssigned = '20181218'
    where Productid = 82167

    --https://limezaim.atlassian.net/browse/BR-5318
    update #docDate
    set LastDayWasAssigned = dateadd(day, 1, LastDayWasAssigned)
    where AssignDate = LastDayWasAssigned
        and AssignDate != @currentDate

    -- https://limezaim.atlassian.net/browse/BR-12998
    -- Удаляем все назначения после даты окончания работы СКГ.
    -- Будущие переходы на СКГ, если снова начнем взаимодействовать, в таблице появятся
    delete -- select *
    from bi.TransferDocumentRegister
    where AssignDate >= '20190809'
        and not exists
        (
            select 1 from bi.vw_CollectorGroupLegalEntity le
            where le.DateFrom >= '20190809'
                and le.TransferIsLogged = 1
        )
    ;
  
    -- https://limezaim.atlassian.net/browse/BR-12998
    -- Мерджим только новые данные, старые оставляем в покое
    merge bi.TransferDocumentRegister t
    using (
        select 
            dd.ProductId
            , dd.OverdueStart
            , dd.AssignDate
            , dd.LastDayWasAssigned
        from #docDate dd
        -- Берем событие снятия с СКГ 
        -- + новые назначения из будущего, если снова будем действовать от имени СКГ
        where dd.LastDayWasAssigned in ('20190809', '20190808')
            or dd.AssignDate >= '20190809'
    ) s
    on s.ProductId = t.ProductId
        and s.AssignDate = t.AssignDate
    when not matched then
        insert (ProductId, OverdueStart, AssignDate, LastDayWasAssigned)
        values (s.ProductId, s.OverdueStart, s.AssignDate, s.LastDayWasAssigned)
    when matched and s.LastDayWasAssigned != t.LastDayWasAssigned then
        update set
            t.LastDayWasAssigned = s.LastDayWasAssigned
    when not matched by source and t.AssignDate >= '20190809'
        then delete
    ;

    delete dr -- select *
    from bi.TransferDocumentRegister dr
    where dr.LastDayWasAssigned > '20190809'
        and not exists
        (
            select 1 from bi.vw_CollectorGroupLegalEntity le
            where le.DateFrom >= '20190809'
                and le.TransferIsLogged = 1
        )
        and exists
        (
            select 1 from bi.TransferDocumentRegister dr2
            where dr2.ProductId = dr.ProductId
                and dr2.LastDayWasAssigned in ('20190809', '20190808')
        )
    ;

end

GO
