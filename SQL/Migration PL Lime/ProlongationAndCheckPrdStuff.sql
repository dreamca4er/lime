with per as 
(
    select
        pcu.id
        , pcu.CreditId
        , cast(pcu.DateCreated as date) as PeriodRequest
        , pcu.Period as Period
        , 'Prolong' as PeriodType
        , pcu.DateCreated as PeriodRequestDT
        , c.Value as CouponPeriod
    from dbo.ProlongCreditUnits pcu
    left join dbo.Coupons c on c.id = pcu.CouponId
    
    union all
    
    select distinct
        null
        , c.id as CreditId
        , cast(c.DateStarted as date)
        , c.Period
        , 'Credit'
        , c.DateStarted
        , null
    from dbo.Credits c
    inner join dbo.ProlongCreditUnits pcu on pcu.CreditId = c.id
)

,pd as 
(
    select *
        , dateadd(d, per.Period, isnull(PrevPayDay, per.PeriodRequest)) as NextPayDay
    from per
    outer apply
    (
        select
            dateadd(d, isnull(sum(per2.Period), 0), min(per2.PeriodRequest)) as PrevPayDay
        from per per2
        where per2.CreditId = per.CreditId
            and per2.PeriodRequestDT < per.PeriodRequestDT
    ) pp
)

,prolong as 
(
    select 
        pd.*
        , csh.*
        , case 
            when datediff(d, PeriodRequestDT, PrevPayDay) > 0
            then datediff(d, PrevPayDay, NextPayDay)
            else datediff(d, PeriodRequestDT, NextPayDay)
        end as CalculatedPeriod
    from pd
    outer apply
    (
        select top 1 
            csh.Status as PeriodRequestStatus
        from dbo.CreditStatusHistory csh
        where csh.CreditId = pd.CreditId
            and csh.DateCreated < pd.PeriodRequestDT
        order by csh.DateCreated desc
    ) csh
    where pd.id is not null
)

select p.*
from prolong p
--where creditid = 14964
--/
where not exists
    (
        select 1 from dbo.CreditStatusHistory csh
        where csh.Status = 3
            and csh.CreditId = p.CreditId
            and cast(csh.DateCreated as date) = dateadd(d, 1, p.NextPayDay)
    )
    and not exists
    (
        select 1 from prolong p2
        where p2.Creditid = p.CreditId 
            and cast(p2.PeriodRequestDT as date) <= p.NextPayDay
            and p2.PeriodRequestDT > p.PeriodRequestDT 
    )
    and not exists
    (
        select 1 from dbo.CreditStatusHistory csh
        where csh.Status in (2, 8)
            and csh.CreditId = p.CreditId
            and cast(csh.DateCreated as date) <= p.NextPayDay
    )
    and CalculatedPeriod > 0
    and NextPayDay < cast(getdate() as date)
    and p.CreditId != 10801
/

select
    c.id
    , c.Status
    , csh.HistoryStatus
from dbo.credits c
outer apply
(
    select top 1 csh.Status as HistoryStatus
    from dbo.CreditStatusHistory csh
    where csh.CreditId = c.id
    order by csh.DateCreated desc
) csh
where c.Status != csh.HistoryStatus
/
select csh.*
from dbo.CreditStatusHistory csh
left join dbo.Credits c on c.id = csh.CreditId
where csh.status in (2, 7, 9)
    and exists
    (
        select 1 from dbo.Payments p
        inner join dbo.CreditPayments cp on cp.PaymentId = p.id
        where cp.CreditId = csh.CreditId
            and cp.DateCreated > csh.DateCreated
    )


select *
from dbo.CreditStatusHistory
where CreditId = 48409

select
    id
    , DatePaid
    , status
from dbo.Credits
where DatePaid is not null
    and status not in (2, 7, 9, 11)


select p.*, cp.DateCreated, cp.id
from dbo.Payments p
inner join dbo.CreditPayments cp on cp.PaymentId = p.id
where cp.CreditId = 37908


select *
from dbo.CreditPayments
where id = 44141