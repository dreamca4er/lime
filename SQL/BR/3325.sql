select
    dtc.TransferDate
    ,c.UserId
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,fu.mobilephone
    ,fu.emailaddress
    ,d.CreditId
    ,cp.DateCreated as PaymentDate
    ,cp.Amount
    ,cp.PercentAmount
    ,cp.TransactionCosts
    ,cp.PenaltyAmount
from dbo.DebtorTransferCession dtc
inner join dbo.Debtors d on d.Id = dtc.DebtorId
inner join dbo.Credits c on c.Id = d.CreditId
inner join dbo.FrontendUsers fu on fu.Id = c.UserId
outer apply
(
    select
        cp.CreditId
        ,cp.DateCreated
        ,sum(cp.Amount) as Amount
        ,sum(cp.PercentAmount) as PercentAmount
        ,sum(cp.TransactionCosts) as TransactionCosts
        ,sum(cp.PenaltyAmount) as PenaltyAmount
    from dbo.CreditPayments cp
    inner join dbo.Payments p on p.Id = cp.PaymentId
        and p.Way != 6
    where cp.CreditId = d.CreditId 
        and cp.DateCreated >= dtc.TransferDate
    group by cp.CreditId,cp.DateCreated
) cp
where dtc.CessionId in (1, 2)
    and cp.CreditId is not null
