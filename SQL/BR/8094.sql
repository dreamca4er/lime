select
    p.ClientId
    , pay.ProductId
    , p.ContractNumber
    , p.StartedOn
    , pay.DateOperation as PaymentDate
    , pay.TotalAmount
    , pay.TotalPercent
    , pay.Fine
    , pay.Commission
    , pay.Prolong
    , pay.TotalDebt
from bi.CreditBalance pay
inner join prd.ShortTermCredit stc on stc.id = pay.ProductId
inner join prd.Product p on p.id = pay.ProductId
left join prd.vw_statusLog sl on sl.ProductId = pay.ProductId
    and sl.Status = 5 
outer apply
(
    select top 1 
        debt.OverdueRestructAmount
    from bi.CreditBalance debt
    where debt.InfoType = 'debt'
        and debt.ProductId = pay.ProductId
        and debt.DateOperation < pay.DateOperation
    order by debt.DateOperation desc
) debt
where pay.DateOperation >= '20180522'
    and pay.InfoType = 'payment'
    and debt.OverdueRestructAmount != 0
    and pay.Fine > 0
    and pay.Prolong >= 0
    and (sl.StartedOn != pay.DateOperation or sl.StartedOn is null) 