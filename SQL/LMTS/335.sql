select
    fu.id as "id Клиента"
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as "ФИО"
    ,floor(datediff(m, fu.Birthday, getdate()) / 12.0) as "Возраст"
    ,isnull(uai.RegRegion, uai.FactRegion) as "Регион"
    ,isnull(uai.RegCityName, uai.FactCityName) as "Город"
    ,otherCredsInfo.paidCreds as "Количество закрытых займов"
    ,otherCredsInfo.paidSum as "Сумма, выплаченная по всем займам"
    ,currCred.debt as "Сумма текущей задолженности"
    ,datediff(d, dateadd(d, max(c.Period) + isnull(sum(lcu.Period), 0), max(c.DateStarted)), getdate()) as "Дней просрочки"    
from dbo.Credits c
inner join dbo.FrontendUsers fu on fu.Id = c.UserId
inner join dbo.UserAdminInformation uai on uai.UserId = c.UserId
left join dbo.LongCreditUnits lcu on lcu.CreditId = c.Id
outer apply
(
    select
        count(distinct case when allCreds.Status = 2 then allCreds.Id else null end) as paidCreds
        ,isnull(sum(cp.Amount + cp.PercentAmount + cp.CommissionAmount + cp.PenaltyAmount + cp.LongPrice + cp.TransactionCosts), 0) as paidSum
    from dbo.Credits as allCreds
    left join dbo.CreditPayments cp on cp.CreditId = allCreds.Id
        and not exists (
                            select 1 from dbo.Payments p
                            where p.id = cp.PaymentId
                                and p.Way = 6
                        )
    where allCreds.UserId = c.UserId
) otherCredsInfo
outer apply 
(
    select top 1 Amount + PercentAmount + CommisionAmount + PenaltyAmount + LongPrice + TransactionCosts as debt
    from dbo.CreditBalances cb
    where cb.CreditId = c.id
        and cb.Amount != 0
    order by cb.Date desc
) currCred
where c.DateCreated >= '20161201'
    and c.Status = 3
group by 
    c.id
    ,fu.id
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '')
    ,fu.Birthday
    ,c.Period
    ,c.DateStarted
    ,otherCredsInfo.paidCreds
    ,otherCredsInfo.paidSum
    ,currCred.debt
    ,isnull(uai.RegRegion, uai.FactRegion)
    ,isnull(uai.RegCityName, uai.FactCityName)
having datediff(d, dateadd(d, max(c.Period) + isnull(sum(lcu.Period), 0), max(c.DateStarted)), getdate()) >= 82

