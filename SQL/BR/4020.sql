select
    p.PaymentWayName
    ,cast(cast(crr.Score * 100 as int) / 5.0 as int) * 0.05 as Score
    ,p.ClientId
    ,p.Productid
    ,p.Amount
    ,case 
        when p.Status = 8 then N'Приостановлен' 
        else p.StatusName
    end as StatusName
    ,p.StartedOn
    ,dateadd(d, p.Period, p.StartedOn) as ContractPayDay
    ,p.DatePaid
    ,cb.*
from prd.vw_product p
outer apply
(
    select top 1
        nullif(crr.Score, 0) as Score
    from cr.CreditRobotResult crr
    where crr.ClientId = p.ClientId
    order by crr.CreatedOn
) crr
outer apply
(
    select 
        sum(cb.TotalAmount) as AmountPaid
        ,sum(cb.TotalPercent) as PercentPaid
        ,sum(cb.TotalDebt - cb.TotalAmount - cb.TotalPercent) as OtherPaid
    from bi.CreditBalance cb
    where cb.ProductId = p.Productid
        and cb.InfoType = 'payment'
) cb
where p.StartedOn >= '20180101'
    and p.Status > 2
order by 1, 2, 3, 4