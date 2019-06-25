select
    pr.ClientId
    , pr.id as ProductId
    , p.ContractNumber
    , p.Amount
    , p.id as PaymentId
    , p.ProcessedOn
    , p.CreatedOn
    , pw.Description as PaymentWay
    , np.*
    , abs(datediff(s, p.ProcessedOn, np.NextProcessedOn))as DiffProcessedOn
    , abs(datediff(s, p.CreatedOn, np.NextCreatedOn))as DiffCreatedOnSec
    , abs(datediff(ms, p.CreatedOn, np.NextCreatedOn))as DiffCreatedOnMS
    , cast(p.ProcessedOn as date) as ProcessedOnDate
from pmt.Payment p
inner join prd.Product pr on pr.ContractNumber = p.ContractNumber
left join pmt.EnumPaymentWay pw on pw.Id = p.PaymentWay
outer apply
(
    select top 1
        p2.id as NextPaymentId
        , p2.ProcessedOn as NextProcessedOn
        , p2.CreatedOn as NextCreatedOn
        , pw2.Description as NextPaymentWay
    from pmt.Payment p2
    left join pmt.EnumPaymentWay pw2 on pw2.Id = p2.PaymentWay
    where p2.ContractNumber = p.ContractNumber
        and p2.PaymentStatus = 5
        and p2.PaymentDirection = 2
        and p2.id > p.id
        and p2.Amount = p.Amount
    order by p2.id
) np
where p.PaymentStatus = 5
    and p.PaymentDirection = 2
    and p.CreatedOn >= '20190101'
    and np.NextProcessedOn is not null
    and 
    (
        abs(datediff(s, p.ProcessedOn, np.NextProcessedOn)) < 15
        or
        abs(datediff(s, p.CreatedOn, np.NextCreatedOn)) < 15
    )
