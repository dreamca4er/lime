select   
    p.Productid
    , p.ClientId
    , p.StartedOn
    , p.StatusName
    , pay.*
from prd.vw_product p
outer apply
(
    select
        sum(pay.Amount) as PaymentSum
        , count(distinct cast(pay.ProcessedOn as date)) as UniquePaymentDates 
        , min(datediff(d, p2.StartedOn, pay.ProcessedOn)) as FirstPaymentDay
    from pmt.Payment pay
    inner join prd.Product p2 on p2.ContractNumber = pay.ContractNumber
    where pay.PaymentStatus = 5
        and pay.ContractNumber = p.ContractNumber
        and pay.ProcessedOn < dateadd(d, 15, p.StartedOn)
        and pay.PaymentDirection = 2
) pay
where p.ProductType = 2
    and p.Status > 2
    and p.StartedOn >= '20190101'
    and pay.PaymentSum >= p.Amount
    and (p.DatePaid is null or datediff(d, p.StartedOn, p.DatePaid) > 14)