select
    p.ClientId
    ,p.Productid
    ,p.ContractNumber
    ,p.StartedOn
    ,p.Amount
    ,p.StatusName
    ,sl.FirstOverdueStart
    ,sl.OverdueCount
    ,cb.TotalAmount
    ,cb.TotalPercent
    ,cb.Commission
    ,cb.Fine
    ,case 
        when slPrev.PrevStatus = 4
        then datediff(d, slPrev.PrevStatusStartedOn, p.DatePaid) + 1
    end as DatePaidOverdueDays
    ,slo.TotalAmountOverdueStart
    ,slo.TotalPercentOverdueStart
    ,slo.CommissionOverdueStart
    ,slo.FineOverdueStart
    ,pay.TotalPaid
from prd.vw_product p
outer apply
(
    select 
        min(sl.StartedOn) as FirstOverdueStart
        ,count(*) as OverdueCount
    from prd.vw_statusLog sl
    where sl.ProductId = p.Productid
        and sl.Status = 4
) sl
outer apply
(
    select top 1 
        cbo.TotalAmount * -1 as TotalAmountOverdueStart
        ,cbo.TotalPercent * -1 as TotalPercentOverdueStart
        ,cbo.Commission * -1 as CommissionOverdueStart
        ,cbo.Fine * -1 as FineOverdueStart
    from bi.CreditBalance cbo
    where cbo.ProductId = p.Productid
        and cbo.InfoType = 'debt'
        and cbo.DateOperation <= sl.FirstOverdueStart
    order by cbo.DateOperation desc
) slo
outer apply
(
    select top 1 
        sl2.Status as PrevStatus
        ,sl2.StartedOn as PrevStatusStartedOn
    from prd.vw_statusLog sl2
    where sl2.ProductId = p.Productid
        and sl2.StartedOn < p.DatePaid
    order by sl2.StartedOn desc
) slPrev
outer apply
(
    select top 1
        cb.TotalAmount * -1 as TotalAmount
        ,cb.TotalPercent * -1 as TotalPercent
        ,cb.Commission * -1 as Commission
        ,cb.Fine * -1 as Fine
    from bi.CreditBalance cb
    where cb.ProductId = p.ProductId
        and cb.InfoType = 'debt'
    order by cb.DateOperation desc 
) cb
outer apply
(
    select sum(cbp.TotalDebt) as TotalPaid
    from bi.CreditBalance cbp
    where cbp.ProductId = p.ProductId
        and cbp.InfoType = 'payment'
) pay
where p.PercentPerDay = 0