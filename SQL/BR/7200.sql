drop table if exists #credits
;

select
    c.id as ProductId
    , c.UserId as ClientId 
    , right('0000' + c.DogovorNumber, 10) as ContractNumber
    , c.DateCreated as ConsentDate
    , c.DateStarted
    , c.DatePaid
    , c.Status
    , c.Amount
    , c.Period
    , iif(TariffId = 4, 2, 1) as ProductType
    , cast(null as numeric (6, 3)) as PSK 
    , cast(null as nvarchar(max)) as Schedule
    , c."Percent" as PercentPerDay
into #credits
from "LIME-DB".LimeZaim_Website.dbo.Credits c
where DogovorNumber in
(
    '1346367006'
    ,'1453386001'
    ,'1486528001'
    ,'1525702002'
    ,'1572626001'
    ,'1631625001'
    ,'773869007'
    ,'566120008'
    ,'184096001'
    ,'626035009'
    ,'654923002'
    ,'727493004'
    ,'694510004'
    ,'415231013'
    ,'502037008'
    ,'830928004'
    ,'864662002'
    ,'893666002'
    ,'909482002'
    ,'842441008'
    ,'886384001'
    ,'797978015'
    ,'873261007'
    ,'900904003'
    ,'806058011'
    ,'914599010'
    ,'955702001'
    ,'939777002'
    ,'976917002'
    ,'954254001'
    ,'942503004'
    ,'934790005'
    ,'930751005'
    ,'1038462001'
    ,'1048118001'
    ,'1052406005'
    ,'1080208011'
    ,'1144881003'
    ,'1205470004'
    ,'1223324003'
    ,'1232602002'
    ,'1211729001'
    ,'1216325003'
    ,'1287869002'
    ,'1240386003'
    ,'1404400001'
    ,'1343695002'
    ,'1332556002'
)
    and c.Status not in (5, 8)
;

update c
set Psk = p.Psk
from #credits c
inner join prd.vw_product p on p.Productid = c.ProductId
;

update c set Schedule = 
    isnull(s.ScheduleSnapshot, 
        (
            select 
                dateadd(d, p.Period, p.StartedOn) as Date
                , p.Amount
                , (p.Amount * p.PercentPerDay * p.Period / 100 + p.Amount) as Total
            from (select 1 a) b
            for json auto
        ))
from #credits c
left join prd.vw_product p on p.Productid = c.ProductId
outer apply
(
    select top 1 j.ScheduleSnapshot
    from prd.LongTermScheduleLog ltsl
    inner join prd.LongTermSchedule lts on lts.id = ltsl.ScheduleId
    outer apply
    (
        select *
        from openjson(lts.ScheduleSnapshot)
        with
        (
            Date datetime2 '$.Date'
            , Amount numeric (18, 2) '$.Amount'
            , "Percent" numeric (18, 2) '$.Percent'
            , Total numeric (18, 2) '$.Total'
        ) oq
        for json path
    ) j(ScheduleSnapshot)
    where lts.ProductId = c.ProductId
    order by ltsl.StartedOn desc
) s
;

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
from "LIME-DB".LimeZaim_Website.dbo.CreditBalances cb
inner join #credits c on c.ProductId = cb.CreditId
    and cb.Date < '20180224'
;

drop table if exists #statuses
;

select
    sl.ProductId
    , cast(sl.StartedOn as date) as StartedOn
    , case 
        when sl.Status in (3, 7) then 'Active'
        when sl.Status = 4 then 'Overdue'
        when sl.Status = 5 then 'Repaid'
        when sl.Status = 6 then 'OnCession'
    end as Status
into #statuses
from prd.vw_statusLog sl
inner join #credits c on c.ProductId = sl.ProductId
    and sl.Status > 2
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
    from "LIME-DB".LimeZaim_Website.dbo.CreditPayments cp
    inner join #credits c on c.ProductId = cp.CreditId
        and cp.DateCreated < '20180225'

    union all
    
    select
        cb.ProductId
        , cast(cast(cb.DateOperation as date) as datetime2)
        , cb.TotalAmount
        , cb.TotalPercent
        , cb.TotalDebt
    from bi.CreditBalance cb
    inner join #credits c on c.ProductId = cb.ProductId
    where cb.InfoType = 'payment'
        and cb.DateOperation >= '20180225'
) cp
;

drop table if exists #prolong
;

select *
into #prolong
from
(
    select
        cast(stp.StartedOn as date) as StartedOn
        , stp.ProductId
        , stp.Period
    from prd.ShortTermProlongation stp
    inner join #credits c on c.ProductId = stp.ProductId
        and stp.CreatedOn >= '20180225'
        and stp.IsActive = 1
    
    union all
    
    select 
        lcu.dt
        , lcu.CreditId
        , lcu.correctPeriod
    from "LIME-DB".LimeZaim_Website.dbo.vw_migrateProlong lcu
    inner join #credits c on c.ProductId = lcu.CreditId
        and lcu.dt < '20180225'
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

,un as 
(
    select *
    from CBOld
    
    union all
    
    select
        cb.ProductId
        , cb.DateOperation
        , cb.ActiveAmount * -1
        , cb.OverdueAmount * -1
        , cb.ActivePercent * -1
        , cb.OverduePercent * -1
        , cb.Fine * -1
        , cb.Commission * -1
    from bi.CreditBalance cb
    inner join #Credits c on c.ProductId = cb.ProductId
    where cb.Infotype = 'debt'
        and cb.DateOperation >= '20180225'
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
/
set nocount on
;

drop table if exists bi.MergedCreditHistory
;

create table bi.MergedCreditHistory 
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
    insert bi.MergedCreditHistory (ProductId, Date, CheckpointType, CreditHistory)
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

