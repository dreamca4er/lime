with CurrentSnapshot as 
(
    select 
        p.Productid
        , p.Amount
        , p.StartedOn
        , p.StatusName
        , p.ScheduleCalculationTypeName
        , tk.TkFactor
        , ss.*
        , c.clientid
        , c.fio
        , c.PhoneNumber
        , iif(c.EmailConfirmed = 1, c.Email, null) as Email
    from prd.vw_product p
    inner join client.vw_Client c on c.clientid = p.ClientId
    outer apply
    (
        select top 1 TkFactor
        from openjson(ConditionSnapshot) with
        (
            TkFactor numeric(10,2) '$.TkFactor'
            , StartedOn datetime '$.SatrtedOn' 
        ) cs
        order by cs.StartedOn desc
    ) tk
    outer apply
    (
        select top 1 lts.ScheduleSnapshot
        from prd.LongTermSchedule lts
        inner join prd.LongTermScheduleLog ltsl on ltsl.ScheduleId = lts.Id
        where lts.ProductId = p.Productid
        order by ltsl.StartedOn desc 
    ) ss
    where 1=1
        and p.Status in (3, 4)
        and p.ProductType = 2
        and p.IsPaused = 0
)

,ParcedSnapshot as 
(
    select *
    from CurrentSnapshot cs
    outer apply openjson(cs.ScheduleSnapshot) with
    (
        Date date '$.Date'
        , ScheduledAmount numeric(18, 2) '$.Amount'
        , ScheduledPercent numeric(18, 2) '$.Percent'
    ) jss
)

select
    ps.clientid
    , ps.fio
    , ps.PhoneNumber
    , ps.Email
    , ps.Productid
    , ps.StartedOn
    , ps.StatusName
    , datediff(d, ps.StartedOn, getdate()) as CreditAgeDays
    , ps.Date as NextPaymentDate
    , datediff(d, cast(getdate() as date), ps.Date) as NextPaymentInDays
    , ps.ScheduleCalculationTypeName
    , ps.Amount
    , ps.ScheduledAmount
    , ps.ScheduledPercent
    , ac.SaldoNt
    , isnull(paid.PaidPercent, 0) as PaidPercent
    , debt.PercentDebt
from ParcedSnapshot ps
outer apply
(
    select sum(cb.TotalPercent) as PaidPercent
    from bi.CreditBalance cb
    where cb.InfoType = 'payment'
        and cb.ProductId = ps.productId 
) paid
outer apply
(
    select top 1 cb.TotalPercent * -1 as PercentDebt
    from bi.CreditBalance cb
    where cb.infotype = 'debt'
        and cb.ProductId = ps.ProductId
    order by cb.DateOperation desc 
) debt
left join acc.vw_acc ac on ac.ProductId = ps.ProductId
    and ac.productType = 2
    and ac.Number like '47422%'
where not exists
    (
        select 1 from ParcedSnapshot ps2
        where ps2.ProductId = ps.ProductId
            and ps2.Date >= cast(getdate() as date)
            and ps2.Date < ps.Date
    )
    and ps.Date >= cast(getdate() as date)
    and datediff(d, cast(getdate() as date), ps.Date) <= 7
    and ps.ScheduledAmount > 0
    and ac.SaldoNt < ps.ScheduledAmount + ps.ScheduledPercent
    and not exists
    (
        select 1 from prd.LongTermProlongation ltp
        where ltp.ProductId = ps.Productid
    )
    and ps.Amount * isnull(ps.TkFactor, 2.5) - (debt.PercentDebt + isnull(paid.PaidPercent, 0)) > 0