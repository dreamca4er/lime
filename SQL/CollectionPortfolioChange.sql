declare 

    @dateFrom date = '20180601'
    ,@dateTo date = '20180619'
    ,@collectorId nvarchar(36) = '414E7E42-D4C4-4C6B-8CD3-06A45277300C'
;

declare 
    @TotalDaysCount int = datediff(d, @dateFrom, @dateTo) + 1
;

drop table if exists #days
;

drop table if exists #col
;

drop table if exists #pay
;

drop table if exists #AssignsDict
;

drop table if exists #UnAssignEvent
;

drop table if exists #AssignEvent
;

drop table if exists #PartialPayEvent
;

drop table if exists #charges
;

drop table if exists #DebtIncresedEvent
;

drop table if exists #colInfo
;

select
    a.id as UserId
    ,a.Name
    ,a.CollectorGroups
into #colInfo
from sts.vw_admins a
;

select *
into #AssignsDict
from 
(
    values 
        (1, N'Назначение', N'Новая группа просрочки')
        ,(2, N'Назначение', N'Переход внутри группы')
        ,(3, N'Назначение', N'Из отстойника')
        ,(4, N'Назначение', N'Иное назначение')
        ,(5, N'Снятие', N'Новая группа просрочки')
        ,(6, N'Снятие', N'Переход внутри группы')
        ,(7, N'Снятие', N'Продлился')
        ,(8, N'Снятие', N'Оплатил полностью')
        ,(9, N'Снятие', N'Иное снятие')
        ,(10, N'Частичная оплата', N'Частичная оплата')
        ,(11, N'Увеличение долга', N'Увеличение долга')
) as assigns(EventType, EventName, EventSubname)
;

select top (@TotalDaysCount)
    dateadd(d, row_number() over (order by name) - 1, @dateFrom) as Date
into #days
from sys.sysobjects
;


select 
    op.*
    ,p.producttype
    ,case when op.AssignDate = '20180609' then 0 else 1 end as OverdueDaysAdd
into #col
from col.tf_op(dateadd(d, -1, @dateFrom), @dateTo) op
inner join prd.vw_product p on p.productid = op.productid
where op.CollectorId in (@collectorId)
;

select
    cast(cb.DateOperation as date) as Date
    ,cb.ProductId
    ,sum(cb.TotalAmount) as TotalAmount
    ,sum(cb.TotalPercent) as TotalPercent
    ,sum(cb.Commission) as Commission
    ,sum(cb.Fine) as Fine
    ,sum(cb.Prolong) as Prolong
    ,sum(cb.TotalDebt) - sum(cb.Prolong) as TotalDebtNoProlong
into #pay
from bi.CreditBalance cb
where cast(DateOperation as date) between dateadd(d, -1, @dateFrom) and @dateTo
    and cb.InfoType = 'payment'
group by 
    cast(cb.DateOperation as date)
    ,cb.ProductId
;

select
    d.Date
    ,c.ProductId
    ,c.ProductType
    ,c.CollectorId
    ,case
        when cg.GroupName is not null then 1
        when cg1.GroupName is not null then 2
        when ColGroupInf.GroupName like N'Нераспр.%' then 3
        else 4
    end as EventType
    ,cb.TotalDebt * -1 as EventSum
into #AssignEvent
from #days d
inner join #col c on d.date = AssignDate
left join col.vw_cg cg on 
    (c.producttype = 1 and datediff(d, c.OverdueStart, c.AssignDate) + 1 = cg.STOverdueDaysMin)
    or (c.producttype = 2 and datediff(d, c.OverdueStart, c.AssignDate) + 1 = cg.LTOverdueDaysMin)
-- Костыль для пропущенных распределений
    or (c.producttype = 1 and datediff(d, c.OverdueStart, c.AssignDate) + OverdueDaysAdd = cg.STOverdueDaysMin)
    or (c.producttype = 2 and datediff(d, c.OverdueStart, c.AssignDate) + OverdueDaysAdd = cg.LTOverdueDaysMin)
left join col.vw_cg cg1 on 
    (c.producttype = 1 and datediff(d, c.OverdueStart, c.AssignDate) + 1 = cg1.STReassignOverdueDays)
    or (c.producttype = 2 and datediff(d, c.OverdueStart, c.AssignDate) + 1 = cg1.LTReassignOverdueDays)
-- Костыль для пропущенных распределений
    or (c.producttype = 1 and datediff(d, c.OverdueStart, c.AssignDate) + OverdueDaysAdd = cg1.STReassignOverdueDays)
    or (c.producttype = 2 and datediff(d, c.OverdueStart, c.AssignDate) + OverdueDaysAdd = cg1.LTReassignOverdueDays)
left join col.CollectorGroup ColGroup on ColGroup.Collectorid = c.PrevCollectorId
left join col.vw_cg ColGroupInf on ColGroupInf.GroupId = ColGroup.Name
outer apply
(
    select top 1
        cb.TotalDebt
    from bi.CreditBalance cb
    where cb.ProductId = c.Productid
        and cb.InfoType = 'debt'
        and cb.DateOperation <= c.AssignDate
    order by cb.DateOperation desc
) cb
;

select
    d.Date
    ,c.ProductId
    ,c.ProductType
    ,c.CollectorId
    ,case
        when cg.GroupName is not null then 5
        when cg1.GroupName is not null then 6
        when cb.TotalDebt * -1 != pay.TotalDebtNoProlong and pay.Prolong > 0 then 7
        when cb.TotalDebt * -1 = pay.TotalDebtNoProlong then 8
        else 9
    end as EventType
    ,cb.TotalDebt as EventSum
into #UnAssignEvent
from #days d
inner join #col c on d.date = dateadd(d, 1, cast(c.LastDayWasAssigned as date))
left join col.vw_cg cg on 
    (c.producttype = 1 and datediff(d, c.OverdueStart, c.LastDayWasAssigned) + 1 = cg.STOverdueDaysMax)
    or (c.producttype = 2 and datediff(d, c.OverdueStart, c.LastDayWasAssigned) + 1 = cg.LTOverdueDaysMax)
-- Костыль для пропущенных распределений
    or (c.producttype = 1 and datediff(d, c.OverdueStart, c.LastDayWasAssigned) + OverdueDaysAdd = cg.STOverdueDaysMax)
    or (c.producttype = 2 and datediff(d, c.OverdueStart, c.LastDayWasAssigned) + OverdueDaysAdd = cg.LTOverdueDaysMax)
left join col.vw_cg cg1 on 
    (c.producttype = 1 and datediff(d, c.OverdueStart, c.LastDayWasAssigned) + 1 = cg1.STReassignOverdueDays - 1)
    or (c.producttype = 2 and datediff(d, c.OverdueStart, c.LastDayWasAssigned) + 1 = cg1.LTReassignOverdueDays - 1)
-- Костыль для пропущенных распределений
    or (c.producttype = 1 and datediff(d, c.OverdueStart, c.LastDayWasAssigned) + OverdueDaysAdd = cg1.STReassignOverdueDays - 1)
    or (c.producttype = 2 and datediff(d, c.OverdueStart, c.LastDayWasAssigned) + OverdueDaysAdd = cg1.LTReassignOverdueDays - 1)
outer apply
(
    select top 1
        cb.TotalDebt
    from bi.CreditBalance cb
    where cb.ProductId = c.Productid
        and cb.InfoType = 'debt'
        and cb.DateOperation < c.LastDayWasAssigned
    order by cb.DateOperation desc
) cb
left join #pay pay on pay.ProductId = c.ProductId
    and dateadd(d, 1, pay.Date) = d.Date
;

select
    dateadd(d, 1, p.Date) as Date
    ,P.ProductId
    ,c.ProductType
    ,c.CollectorId
    ,10 as EventType
    ,p.TotalDebtNoProlong * -1 as EventSum
into #PartialPayEvent
from #pay p
inner join #col c on p.Date between c.AssignDate and c.LastDayWasAssigned
    and c.ProductId = p.ProductId
where not exists
    (
        select 1 from #UnAssignEvent uae
        where uae.ProductId = c.ProductId
            and uae.Date = dateadd(d, 1, p.Date)
    )
;    

select
    ProductId
    ,DocumentDate as Date
    ,ProductType
    ,sum(opSum) as ChargeSum
into #charges
from acc.vw_mm
where OperationTemplateId in (select id from acc.OperationTemplate ot where ot.Name = 'Charge')
    and DocumentDate between @dateFrom and @dateTo
    and ProductId in (select ProductId from #col)
    and left(accNumber, 5) in ('48802', N'Штраф')
group by 
    ProductId
    ,DocumentDate
    ,ProductType
;

create index IX_charges_ProductId_Date on #charges(ProductId, Date)
;

select
    ch.Date
    ,ch.ProductId
    ,ch.ProductType
    ,c.CollectorId
    ,11 as EventType
    ,ch.ChargeSum * -1 as EventSum
into #DebtIncresedEvent
from #col c
inner join #charges ch on ch.Date between c.AssignDate and c.LastDayWasAssigned
    and c.ProductId = ch.ProductId
    and not exists 
        (
            select 1 from #AssignEvent ae
            where ae.productid = c.ProductId
                and ae.Date = ch.Date
        )
;

with AssignEvent as 
(
    select
        Date
        ,collectorid
        ,EventType
        ,ProductType
        ,count(distinct ProductId) as ProductCount
        ,sum(EventSum) as EventSum
    from #AssignEvent
    group by 
        Date
        ,collectorid
        ,EventType
        ,ProductType
)

,UnAssignEvent as 
(
    select
        Date
        ,collectorid
        ,EventType
        ,ProductType
        ,count(distinct ProductId) as ProductCount
        ,sum(EventSum) as EventSum
    from #UnAssignEvent
    group by 
        Date
        ,collectorid
        ,EventType
        ,ProductType
)

,PartialPayEvent as 
(
    select
        Date
        ,collectorid
        ,EventType
        ,ProductType
        ,count(distinct ProductId) as ProductCount
        ,sum(EventSum) as EventSum
    from #PartialPayEvent
    group by 
        Date
        ,collectorid
        ,EventType
        ,ProductType
)   

,DebtIncresedEvent as 
(
    select
        Date
        ,collectorid
        ,EventType
        ,ProductType
        ,count(distinct ProductId) as ProductCount
        ,sum(EventSum) as EventSum
    from #DebtIncresedEvent
    group by 
        Date
        ,collectorid
        ,EventType
        ,ProductType
)

,un as 
(
    select *
    from AssignEvent
    union all
    select *
    from UnAssignEvent
    union all
    select *
    from PartialPayEvent
    union all
    select *
    from DebtIncresedEvent
)

select
    un.Date
    ,un.CollectorId
    ,ci.name as CollectorName
    ,ci.CollectorGroups
    ,un.EventSum
    ,un.ProductCount
    ,un.ProductType
    ,ad.*
    ,cp1.Portfolio as CurrentDayPortfolio
    ,cp2.Portfolio as PreviousDayPortfolio
from un
inner join #AssignsDict ad on un.EventType = ad.EventType
inner join #colInfo ci on ci.userid = un.collectorid
left join bi.CollectorPortfolio cp1 on cp1.Date = un.date
    and cp1.CollectorId = un.CollectorId
left join bi.CollectorPortfolio cp2 on cp2.Date = dateadd(d, -1, un.date)
    and cp2.CollectorId = un.CollectorId
    

;
/
select  top 100 *
from bi.CollectorPortfolio 
order by date desc