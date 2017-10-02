select
    case
        when p.Way = -3 then N'Карта'
        else 'Qiwi'
    end as moneyWay
    ,isnull(p.CardNumber, fu.MobilePhone) as client
    ,case
        when c.CardType = 1 then 'VISA'
        when c.CardType = 2 then 'MasterCard'
    end as CardType
    ,c.Holder
    ,format(p.DateCreated, 'dd.MM.yyyy HH:mm') as TransactionStart
    ,format(p.DateLastUpdated, 'dd.MM.yyyy HH:mm') as TransactionComplete
    ,'RUB' as Currency
    ,p.Amount
    ,p.OrderDescription
    ,edu.Description as Status
    ,format(cp.cpDate, 'dd.MM.yyyy HH:mm') as lastPaymentDate
    ,cp.cpPaid
    ,N'Погашение по договору займа № ' + cred.DogovorNumber 
    + N' от ' + format(p.DateCreated, 'dd.MM.yyyy HH:mm') 
    + N' клиент: ' + fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '')
from dbo.Payments p
inner join dbo.Credits cred on cred.BorrowPaymentId = p.Id
inner join dbo.EnumDescriptions edu on edu.Value = cred.Status
    and edu.Name = 'CreditStatus'
inner join dbo.FrontendUsers fu on fu.Id = p.FrontendUserId
left join dbo.Cards c on c.CardId = p.CardId
outer apply
(
    select
        max(cp.DateCreated) as cpDate
        ,sum(cp.Amount + cp.PercentAmount + cp.CommissionAmount + cp.PenaltyAmount + cp.LongPrice + cp.TransactionCosts) as cpPaid
        ,max(nvp.DateCreated) as pDate
        ,sum(nvp.Amount) as pPaid
    from dbo.Payments nvp
    left join dbo.CreditPayments cp on nvp.Id = cp.PaymentId
    where nvp.FrontendUserId = p.FrontendUserId
        and nvp.DateCreated >= cred.DateStarted
        and (cred.DatePaid is null or nvp.DateCreated <= cred.DatePaid)
        and nvp.Way != 6
        and nvp.ParentPaymentId is null
) cp
where p.ParentPaymentId is null
    and p.Way in (-3, -4)
    and p.Status = 3
    and cast(p.DateCreated as date) between '20170401' and '20170630'
order by p.DateCreated
