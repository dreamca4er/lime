declare
    @StartDate date = '20170401'
    ,@EndDate date = '20170630'
;

with CanceledCredits as --отменные платежи 
(
    select cp.CreditId
    from Credits as c 
    inner join CreditPayments as cp on cp.CreditId = c.Id
    inner join Payments as p on p.Id = cp.PaymentId
    where c.[Status] = 2 --кредит погашен
    group by cp.CreditId
    having count(*) = count(case when p.Way = 6 and p.status = 3 then 1 end)

)


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
left join dbo.UserCards uc on uc.UserId = fu.id
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
where cred.Way in (-3, -4)
    and cred.Status not in (5, 8)
    and cast(cred.DateStarted as date) between '20170401' and '20170630'
    and cred.id not in (select creditid from CanceledCredits)
--    and uc.IsFraud = 0
order by p.DateCreated
