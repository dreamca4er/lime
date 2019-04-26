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
where c.id in 
(
34296,153952,180044,267349,307804,308891,331163,335027,344391,352934,332639,349855,134380,138499,128258,124462,309507,324877,326097,329704,330812,320317,333530,347719,355098,341280,342993,350604,296568,305749,323434,305645,331302,348860,349887,217600,281782,350916,351004,282463,331276,344632,346300,346726,257036,230464,309160,312247,302662,303591,320934,329852,342023,344959,350809,354886,356060,356231,332523,227350,310561,283837,319415,328082,317556,336760,339796,324038,342513,348294,348603,350759,350842,352972,349060,353495,353503,333077,334469,338738,338808,355011,172049,280968,307779,315132,316349,324896,325342,325734,327467,330162,331328,321807,321830,332622,342482,343606,346287,347617,349208,349222,351273,338905,342625,344381,351209,136791,150237,166931,106073,146495,149275,233100,167865,168314,214480,270398,275906,276151,220686,221689,224259,236276,242747,244518,251290,194098,263807,277692,277693,278190,306195,281731,308776,309868,309989,310582,310596,312008,312108,312513,315251,316808,285698,291696,259600,295613,319512,297814,298891,261437,302759,320424,321013,321318,303679,304637,321968,321999,322536,307002,325193,325858,307148,326266,327612,311577,328778,313446,329431,314103,317620,331124,331148,331283,317730,318234,300404,301416,320422,333427,333460,323882,336237,338456,339075,339361,339744,339812,330692,332926,334257,332341,332883,341016,341057,344789,345892,356017,260153,271789,284831,324006,330611,330642,335671,335804,336511,338176,340217,340316,340585,341278,341420,343124,343754,346350,347111,347643,348290,140271,131423,131263,129306,127943,127191,127124,126666,126380,152607,153685,154774,159143,159527,124763,124251,124216,165727,122718,122145,121550,172104,173178,121273,120541,117687,117592,110192,147113,147239,148357,156964,167415,257181,205875,213956,270079,273261,217808,232153,185368,189748,194595,198611,305931,305975,310321,212265,121617,222738,257171,267314,302268,293998,301332,318478,150672,330569,350194,350242,350271,350307,350423,350309,332174,351891,351977,352113,352117,348505,350499,355134,133075,320638,346963,355165,355333,130664,133884,135378,135727,161011,355125,146937,120381,142778,350598,141613,135041,163336,135262,348556,142156,348634,135572,162930,153363,156127,177190,347702,139699,336449,346075,346985,347936,354226,355373,345561,167001,125338,161145,334762,341205,334780,319759,347006,151146,151364,336346,351083,249197,175679,194915,278741,239145,247181,299550,301924,267753,308507,309631,282002,312215,291697,259341,321464,306946,316556,318904,339174,339254,339302,339516,339711,326019,328305,329014,319746,319888,333095,334310,345443,346533,345958,343157,348507,331677,352653,355562,352183,355106,348822,145498,171572,352761,319832,352257,355745,325022,325092,319175,348203,349117,271325,352633,346465,353047,353086,354325,347830,346056,336202,340626,345602,339700,339997,340169,341227,345737,342582
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
            , max(sch.Date) as PreviousScheduleDate
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
                else round(c.PercentPerDay  / 100 * isnull(schleft.ScheduledAmount, 0), 2)
                    * datediff(d, isnull(PreviousScheduleDate, c.DateStarted), cb.date)
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
        , (cb.ActiveAmount + cb.RestructAmount) * -1
        , (cb.OverdueAmount + cb.OverdueRestructAmount) * -1
        , (cb.ActivePercent + cb.RestructPercent) * -1
        , (cb.OverduePercent + cb.OverdueRestructPercent) * -1
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
/*
drop table if exists bi.MergedCreditHistory
;

create table bi.MergedCreditHistory 
(
    id int identity(1, 1)
    , ProductId int
    , Date date
    , CheckpointType nvarchar(20)
    , CreditHistory nvarchar(max)
    , IssueNum nvarchar(20)
    
)
;

create index IX_bi_MergedCreditHistoryProductId on bi.MergedCreditHistory(ProductId)
;

create index IX_bi_MergedCreditHistory_IssueNum on bi.MergedCreditHistory(IssueNum)
;

*/

insert bi.MergedCreditHistory (ProductId, Date, CheckpointType, CreditHistory, IssueNum)
select
    ch.ProductId
    , d.Date
    , d.CheckpointType
    , ch.CreditHistory
    , 'BR-7332' 
from #dates d
cross apply
(
    select
        cr.ProductId
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
            and cp.Date <= d.Date
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
            and p.StartedOn <= d.Date
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
            and b.Date <= d.Date
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
    where cr.ProductId = d.ProductId
        and not exists 
        (
            select 1 from bi.MergedCreditHistory mch
            where mch.ProductId = d.ProductId
                and mch.CheckpointType = d.CheckpointType
                and mch.Date = d.Date
        )
) ch
/

select *
from bi.MergedCreditHistory
where IssueNum = 'BR-7332'
    and ProductId = 106073