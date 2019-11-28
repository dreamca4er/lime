--drop table if exists dbo.with_prolong
--;
--
--select 
--    c.id as CreditId
--    , c.DateStarted
--    , c.Period
--into dbo.with_prolong
--from dbo.Credits c
--where c.DateStarted is not null
--    and exists
--    (
--        select 1 from dbo.LongCreditUnits lcu
--        where lcu.CreditId = c.id
--    )

declare
    @CreditId int = 44659--(select top 1 CreditId from dbo.with_prolong order by newid())
;
with periods as 
(
    select *
    from dbo.with_prolong wp
    
    union all
    
    select
        lcu.CreditId
        , cast(lcu.DateCreated as date) as DateStarted
        , sum(lcu.Period) as Period
    from dbo.LongCreditUnits lcu
    where 1=1
    group by lcu.CreditId, cast(lcu.DateCreated as date)
)

,pd as 
(
    select per.*
        , wp.DateStarted as CreditStartedOn
        , dateadd(d
            , sum(per.Period) over (partition by per.CreditId order by per.DateStarted)
            , wp.DateStarted) as PayDay
    from periods per
    inner join dbo.with_prolong wp on wp.Creditid = per.CreditId
)

,calc as 
(
    select
        *
        , datediff(d, DateStarted, PayDay)
            + case 
                when lag(PayDay) over (partition by CreditId order by DateStarted) > DateStarted
                then datediff(d, lag(PayDay) over (partition by CreditId order by DateStarted), DateStarted)
                else 0
            end as RealPeriod
    from pd
)

select 
    calc.CreditId
    , calc.DateStarted as StartedOn
    , calc.RealPeriod as Period
from calc
where calc.DateStarted != calc.CreditStartedOn

