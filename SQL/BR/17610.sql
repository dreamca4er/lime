--exec bi.sp_GenerateMergedCreditHistory '["0131165001", "0121551001"]'
--/
exec sp_rename 'dbo.PSK', 'AdditionalCreditInfo'
select top 10 * from prd.vw_product
where CreatedOn < '20180201' and DatePaid >= '20190804'
and producttype = 2
/
create or alter procedure bi.sp_GenerateMergedCreditHistory(@ContractNumbers nvarchar(max)) as 
begin
--    declare @ContractNumbers nvarchar(max) = '["1346367003"]'
    declare @NewProjectStartedOn date = (select NewProjectStartedOn from bi.ProjectConfig)
    ;
    
    drop table if exists #ContractNumbers
    select distinct value as ContractNumber
    into #ContractNumbers
    from openjson(@ContractNumbers)
    ;
    
    drop table if exists #credits
    select
        c.id as ProductId
        , c.UserId as ClientId 
        , right('0000' + c.DogovorNumber, 10) as ContractNumber
        , c.DogovorNumber as DogovorNumber
        , c.DateCreated as ConsentDate
        , c.DateStarted
        , c.DatePaid
        , c.Status
        , c.Amount
        , c.Period
        , iif(TariffId = 4, 2, 1) as ProductType
        , s.PSK 
        , s.Schedule
        , c."Percent" as PercentPerDay
    into #credits
    from "OLD-PROJECT-DB".LimeZaim_Website.dbo.Credits c
    left join "OLD-PROJECT-DB".LimeZaim_Website.dbo.AdditionalCreditInfo s on s.CreditId = c.Id
    where DogovorNumber in
    (
        select cast(cast(ContractNumber as bigint) as nvarchar(10)) from #ContractNumbers
    )
        and c.Status not in (5, 8)
    ;
    
    declare @NotFound nvarchar(max) = 
    (
        select string_agg(ContractNumber, ', ')
        from #ContractNumbers con
        where not exists
        (
            select 1 from #credits c
            where c.DogovorNumber = con.ContractNumber
        )
    )
    ;
 
    if (select count(*) from #credits) != (select count(*) from #ContractNumbers)
    begin
        raiserror (N'Номер(а) договора %s не найден(ы) на старом проекте', 16, 1, @NotFound)
        return
    end
   
    drop table if exists #cb
    ;
    
    select
        cb.CreditId as ProductId
        , dateadd(d, 1, cb.Date) as Date
        , cb.Amount
        , cb.PercentAmount as "Percent"
        , 0 as Penalty
        , cb.TransactionCosts + cb.CommisionAmount as LoanComission
    into #cb
    from "OLD-PROJECT-DB".LimeZaim_Website.dbo.CreditBalances cb
    inner join #credits c on c.ProductId = cb.CreditId
        and cb.Date < dateadd(d, -1, @NewProjectStartedOn)
    ;
    
    drop table if exists #statuses
    select
        csh.CreditId as ProductId
        , csh.DateStarted as StartedOn
        , case 
            when np.Status in (3, 7) then 'Active'
            when np.Status = 4 then 'Overdue'
            when np.Status = 5 then 'Repaid'
            when np.Status = 6 then 'OnCession'
            else cast(np.Status as nvarchar(20))
        end as Status
    into #statuses
    from "OLD-PROJECT-DB".LimeZaim_Website.dbo.CreditStatusHistory csh
    inner join #Credits c on c.ProductId = csh.CreditId
    outer apply (select choose(csh.Status, 3,5,4,0,2,0,5,1) as Status) np
    where csh.Status not in (5, 8)
        and cast(csh.DateStarted as date) < @NewProjectStartedOn
    ;
    
    insert #statuses
    select
        sl.ProductId
        , cast(sl.StartedOn as date) as StartedOn
        , case 
            when sl.Status in (3, 7) then 'Active'
            when sl.Status = 4 then 'Overdue'
            when sl.Status = 5 then 'Repaid'
            when sl.Status = 6 then 'OnCession'
        end as Status
    from prd.vw_statusLog sl
    inner join #credits c on c.ProductId = sl.ProductId
        and sl.Status > 2
    where cast(sl.StartedOn as date) >= @NewProjectStartedOn
    ;
    
    drop table if exists #cp
    ;
    
    select *
    into #cp
    from
    (
        select
            c.ProductId
            , cast(cast(cp.DateCreated as date) as datetime2) as Date
            , cp.Amount
            , cp.PercentAmount
            , cp.PercentAmount + cp.CommissionAmount + cp.PenaltyAmount + cp.LongPrice + cp.TransactionCosts as Total
        from "OLD-PROJECT-DB".LimeZaim_Website.dbo.CreditPayments cp
        inner join "OLD-PROJECT-DB".LimeZaim_Website.dbo.Payments p on p.Id = cp.paymentId
            and p.Way != 6
        inner join #credits c on c.ProductId = cp.CreditId
            and cp.DateCreated < @NewProjectStartedOn
    
        union all
        
        select
            sc.ProductId
            , sc.BusinessDate
            , sum(case when sc.SumType / 1000 = 1 then Sum * -1 else 0 end) as TotalAmount
            , sum(case when sc.SumType / 1000 = 2 then Sum * -1 else 0 end) as TotalPercent
            , sum(Sum * -1) as TotalPaid
        from acc.ProductSumJournal sc
        inner join #credits pl on pl.ProductId = sc.ProductId
            and pl.productType = sc.productType
        where sc.ProductType in (1, 2)
            and sc.SumType in (1001, 1002, 1003, 1004, 2001, 2002, 2003, 2004, 4011, 4012, 3021)
            and sc.ChangeType = 4
            and cast(sc.BusinessDate as date) >= @NewProjectStartedOn
        group by sc.ProductId, sc.BusinessDate
    ) cp
    ;
    
    drop table if exists #prolong
    ;
    
    select *
    into #prolong
    from
    (
        select
            pr.StartedOn
            , pr.ProductId
            , pr.Period
        from prd.vw_Prolongation pr
        inner join #credits c on c.ProductId = pr.ProductId
        where pr.BuiltOn >= @NewProjectStartedOn
        
        union all
        
        select 
            lcu.dt
            , lcu.CreditId
            , lcu.correctPeriod
        from "OLD-PROJECT-DB".LimeZaim_Website.dbo.vw_migrateProlong lcu
        inner join #credits c on c.ProductId = lcu.CreditId
            and lcu.dt < @NewProjectStartedOn
    ) p
    ;
    
    drop table if exists #balances
    ;
    
    with CBOld as 
    (
        select
            cb.ProductId
            , cb.Date
            , aa.ActiveAmount as Amount
            , cb.Amount - aa.ActiveAmount as OverdueAmount
            , ap.ActivePercent as "Percent"
            , cb."Percent" - ap.ActivePercent as OverduePercent
            , cb.Penalty
            , cb.LoanComission
        from #cb cb
        inner join #credits c on c.ProductId = cb.ProductId
        outer apply
        (
            select top 1 st.Status
            from #statuses st 
            where st.ProductId = cb.ProductId
                and cast(st.StartedOn as date) <= cb.Date
            order by st.StartedOn desc
        ) st
        outer apply
        (
            select
                sum(sch.Amount) as ScheduledAmount
                , count(*) as SchedulePaymentsCount
            from openjson(c.Schedule) 
            with
            (
                Date date '$.Date'
                , Amount numeric(18, 2) '$.Amount'
            ) sch
            where sch.Date < cb.Date
        ) sch
        outer apply
        (
            select
                sum(sch.Amount) as ScheduledAmount
            from openjson(c.Schedule) 
            with
            (
                Date date '$.Date'
                , Amount numeric(18, 2) '$.Amount'
            ) sch
            where sch.Date >= cb.Date
        ) schleft
        outer apply
        (
            select 
                case
                    when c.ProductType = 1 and st.Status = 'Active' then cb.Amount
                    when c.ProductType = 1 and st.Status = 'Overdue' then 0
                    else isnull(schleft.ScheduledAmount, 0) 
                end as ActiveAmount
        ) aa
        outer apply
        (
            select
                case
                    when c.ProductType = 1 and st.Status = 'Active' then cb."Percent"
                    when c.ProductType = 1 and st.Status = 'Overdue' then 0
                    else sum(round(c.PercentPerDay  / 100 * isnull(schleft.ScheduledAmount, 0), 2)) 
                        over (partition by cb.ProductId, sch.SchedulePaymentsCount order by cb.Date) 
                end as ActivePercent
        ) ap
    )
    
    ,cb as 
    (
        select
            sc.ProductId
            , sc.BusinessDate
            , sum(sum(case when sc.SumType in (1001, 1003) then sum else 0 end)) 
                    over (partition by sc.productid order by sc.BusinessDate rows unbounded preceding)  as ActiveAmount
            , sum(sum(case when sc.SumType in (1002, 1004) then Sum else 0 end)) 
                    over (partition by sc.productid order by sc.BusinessDate rows unbounded preceding)  as OverdueAmount
            , sum(sum(case when sc.SumType in (2001, 2003) then Sum else 0 end)) 
                    over (partition by sc.productid order by sc.BusinessDate rows unbounded preceding)  as ActivePercent
            , sum(sum(case when sc.SumType in (2002, 2004) then Sum else 0 end)) 
                    over (partition by sc.productid order by sc.BusinessDate rows unbounded preceding)  as OverduePercent
            , sum(sum(case when sc.SumType = 3021 then Sum else 0 end)) 
                    over (partition by sc.productid order by sc.BusinessDate rows unbounded preceding) as Fine
            , sum(sum(case when sc.SumType = 4011  then Sum else 0 end)) 
                    over (partition by sc.productid order by sc.BusinessDate rows unbounded preceding)  as Commission
        from acc.ProductSumJournal sc
        inner join #Credits c on c.ProductId = sc.ProductId
        where sc.ProductType in (1, 2)
            and sc.SumType in (1001, 1002, 1003, 1004, 2001, 2002, 2003, 2004, 4011, 3021)
        group by sc.ProductId, sc.BusinessDate
    )
    
    ,un as 
    (
        select *
        from CBOld
        
        union all
        
        select *
        from cb
        where BusinessDate >= @NewProjectStartedOn
    )
        
    select *
    into #balances
    from un
    ;
    
    drop table if exists #dates
    ;
    
    with d as 
    (
        select
            ProductId
            , cast(StartedOn as date) as Date
            , 'Status' as CheckpointType
        from #statuses
        
        union all
        
        select
            s.ProductId
            , cast(dateadd(d, od.OverdueDay - 1, s.StartedOn) as date) as Date
            , 'Overdue day ' + cast(od.OverdueDay as nvarchar(3)) as CheckpointType
        from #statuses s
        cross join 
        (
            values (6),(30),(60),(90),(120),(150),(180),(210),(240)
        ) od(OverdueDay)
        where s.Status = 'Overdue'
        
        union all
        
        select
            cp.ProductId
            , cp.Date
            , 'Payment'
        from #cp cp
        
        union all
        
        select
            p.ProductId
            , p.StartedOn
            , 'Prolong'
        from #prolong p
    )
    
    select distinct
        ProductId
        , Date
        , CheckpointType
    into #dates
    from d
    where exists 
        (
            select 1 from #balances b
            where b.ProductId = d.ProductId
                and b.Date = d.Date
        )
        and not exists 
        (
            select 1 from d d2
            where d2.ProductId = d.ProductId
                and d2.Date = d.Date
                and d2.CheckpointType > d.CheckpointType
        )
    ;
    
    set nocount on
    ;
    
    drop table if exists #MergedCreditHistory
    ;
    
    create table #MergedCreditHistory 
    (
        id int identity(1, 1)
        , ProductId int
        , Date date
        , CheckpointType nvarchar(20)
        , CreditHistory nvarchar(max)
    )
    ;
    
    declare 
        @ProductId int
        , @Date date
        , @CheckpointType nvarchar(20)
    ;
    
    declare DatesCursor cursor for select * from #dates order by ProductId, Date
    ;
    
    open DatesCursor
    ;
    
    fetch next from DatesCursor into @ProductId, @Date, @CheckpointType
    ;
    
    while @@FETCH_STATUS = 0
    begin
        insert #MergedCreditHistory (ProductId, Date, CheckpointType, CreditHistory)
        select
            cr.ProductId 
            , @Date
            , @CheckpointType
            , json_modify(json_modify(json_modify(json_modify(j.maininfo
                            , '$.Credits', json_query(replace(ci.creditinfo, ',"Prolognation":null', '')))
                            , '$.RegAddress', json_query(ra.RegAddress))
                            , '$.FactAddress', json_query(isnull(fa.FactAddress, ra.RegAddress)))
                            , '$.CreditRejectRequests', json_query('[]')) as CreditHistory
        from #credits cr
        outer apply
        (
            select top 1
                a.PostalCode as "Index"
                , isnull(left(a.OKATO, 2), '77') as OkatoRegionCode
                , a.Region as RegionName
                , a.RegionCode
                , a.City
                , null as District
                , a.Street
                , a.House
                , null as Building
                , a.Block
                , a.Apartment as Flat
            from Client.vw_address a
            where a.ClientId = cr.ClientId
                and a.AddressType = 1
            for json auto, without_array_wrapper, include_null_values
        ) ra(RegAddress)
        outer apply
        (
            select top 1
                a.PostalCode as "Index"
                , isnull(left(a.OKATO, 2), '77') as OkatoRegionCode
                , a.Region as RegionName
                , a.RegionCode
                , a.City
                , null as District
                , a.Street
                , a.House
                , null as Building
                , a.Block
                , a.Apartment as Flat
            from Client.vw_address a
            where a.ClientId = cr.ClientId
                and a.AddressType = 2
            for json auto, without_array_wrapper, include_null_values
        ) fa(FactAddress)
        outer apply
        (
            select
                st.Status
                , st.StartedOn
            from #statuses st
            outer apply
            (
                select top 1 st2.Status as PrevStatus
                from #statuses st2
                where st2.ProductId = st.ProductId
                    and st2.StartedOn < st.StartedOn
                order by st2.StartedOn desc
            ) st2
            where st.ProductId = cr.ProductId
                and (st2.PrevStatus is null or st2.PrevStatus != st.Status)
            for json auto
        ) st(statuses)
        outer apply
        (
            select
                cp.Date
                , cp.Amount
                , cp.Total
            from #cp cp
            where cp.ProductId = cr.ProductId
                and cp.Date <= @Date
            for json auto
        ) cp(payments)
        outer apply
        (
            select
                p.StartedOn
                , p.Period
                , isnull(prev.OldDateToPay, dateadd(d, cr.Period, cr.DateStarted)) as OldDateToPay
                 , dateadd(d, p.Period - 1, p.StartedOn) as NewDateToPay
            from #prolong p
            outer apply
            (
                select top 1 
                    dateadd(d, p2.Period - 1, p2.StartedOn) as OldDateToPay
                from #prolong p2
                where p2.ProductId = p.ProductId
                    and p2.StartedOn < p.StartedOn
                order by p2.StartedOn desc
            ) prev
            where p.ProductId = cr.ProductId
                and p.StartedOn <= @Date
            for json auto
        ) prolong(Prolognation)
        outer apply
        (
            select top 1
                b.Amount
                , b.LoanComission
                , b.OverdueAmount
                , b.OverduePercent
                , b.Penalty
                , b."Percent"
            from #balances b
            where b.ProductId = cr.ProductId
                and b.Date <= @Date
            order by Date desc
            for json auto, without_array_wrapper
        ) bal(Balance)
        outer apply
        (
            select 
                cr.ProductId
                , cr.ClientId
                , cr.ProductType
                , ContractNumber
                , cr.Amount
                , cr.Psk as FullLoanCost
                , json_query(st.statuses) as StatusLog
                , json_query(cr.Schedule) as SchedulePayments
                , json_query(cp.payments) as Payments
                , json_query(prolong.Prolognation) as Prolognation
                , json_query(bal.Balance) as Balance
            from (select 1 a) b
            for json auto, include_null_values
        ) ci (creditinfo)
        outer apply
        (
            select
                c.clientid as Id
                , c.PhoneNumber as MobilePhone
                , c.FirstName
                , c.LastName
                , c.FatherName
                , c.BirthDate
                , c.BirthPlace
                , c.Passport as PassportNum
                , c.IssuedOn as PassportIssuedOn
                , c.IssuedBy as PassportIssuedBy
                , c.SNILS
                , c.INN
                , cr.ConsentDate
            from Client.vw_client c
            where c.ClientId = cr.ClientId
            for json auto, without_array_wrapper, include_null_values
        ) j(maininfo)
        where cr.ProductId = @ProductId
        ;
        
        fetch next from DatesCursor into @ProductId, @Date, @CheckpointType
        ;
    end
    
    close DatesCursor
    ;
    
    deallocate DatesCursor
    ;
    
    select *
    from #MergedCreditHistory       
end