drop table if exists #Cession
;

select *
into #Cession
from openquery
(
    "MANGO-DB"
    ,'select
        c.Name as CessionName
        ,d.CreditId
        ,cr.DogovorNumber as ContractNumber
        ,cr.UserId as ClientId
    from LimeZaim_Website.dbo.DebtorTransferCession dtc
    inner join LimeZaim_Website.dbo.Debtors d on d.id = dtc.DebtorId
    inner join LimeZaim_Website.dbo.Cessions c on c.Id = dtc.CessionId
    inner join LimeZaim_Website.dbo.Credits cr on cr.Id = d.CreditId'
)
;

select
   c.clientid
   ,c.fio
   ,pr.Productid
   ,pr.ContractNumber
   ,pr.StartedOn
   ,pr.Period
   ,pr.Amount
   ,pr.PaymentWayName
   ,pr.ProductTypeName
   ,cb.*
from client.vw_client c
inner join prd.vw_product pr on pr.ClientId = c.clientid
outer apply
(
    select top 1 
        cb.TotalAmount * -1 as AmountDebt
        ,cb.TotalPercent * -1 as PercentDebt
        ,cb.Commission * -1 as CommissionDebt 
        ,cb.Fine * -1 as FineDebt
    from bi.CreditBalance cb
    where cb.ProductId = pr.Productid
        and cb.InfoType = 'debt'
    order by cb.DateOperation desc
) cb
where pr.Status in (2, 3, 4, 7)
    and 
    (
        (c.IsFrauder = 1 and c.IsFrauderChangedAt >= '20180101')
        or
        (c.IsDead = 1 and c.IsDeadChangedAt >= '20180101')
    )
    and c.clientid not in (select clientid from #Cession)