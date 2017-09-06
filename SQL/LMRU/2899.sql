with creditsCte as 
(
    select distinct 
        c.id as creditid
        ,c.UserId
        ,dch.DateCreated
    from dbo.DebtorCollectorHistory dch
    inner join dbo.Debtors d on d.id = dch.DebtorId
    inner join dbo.Credits c on c.id = d.CreditId
    where cast(dch.DateCreated as date) = '20170802'
        and dch.CollectorId = 1174
)

,lcu as 
(
    select *
    from dbo.LongCreditUnits lcu
    where lcu.CreditId in (select creditid from creditsCte)
        and lcu.DateCreated >= '20170801'
)

select
    cc.userid as "Клиент"
    ,cp.DateCreated as "Дата платежа"
    ,cp.Amount as "Платеж по телу кредита"
    ,cp.PercentAmount 
        + cp.CommissionAmount 
        + cp.PenaltyAmount 
        + cp.PenaltyAmount 
        + cp.LongPrice 
        + cp.TransactionCosts as "Прочий платеж"
from creditsCte cc
inner join dbo.CreditPayments cp on cp.CreditId = cc.creditid
    and cp.DateCreated >= '20170802'
    and not exists (
                    select 1 from dbo.Payments p
                    where p.Id = cp.PaymentId
                        and p.Way = 6
                   )