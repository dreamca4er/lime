declare @startDate date = '20170701', @endDate date = '20170801';

select 
    u.Id as 'Id',
    u.Lastname as 'Lastname',
    u.Firstname as 'Firstname',
    u.Fathername as 'Fathername',
    case 
        when uc.Gender = 1 then N'Мужской' 
        else N'Женский' 
    end as 'Gender',
    convert(varchar, u.Birthday, 104) as 'Birthday',
    uc.BirthPlace as 'BirthPlace',
    uc.Passport as 'Passport',
    convert(varchar, uc.PassportIssuedOn, 104) as 'PassportIssuedOn',
    a.RegAddressString as 'RegAddressString',
    a.FactAddressString as 'FactAddressString',
    u.MobilePhone as 'MobilePhone',
    uc.HomePhone as 'HomePhone',
    uc.AdditionalPhone as 'AdditionalPhone',
    uc.WorkPhone as 'WorkPhone',
    uc.ParentPhone as 'ParentPhone',
    convert(varchar, c.DateStarted, 104) as 'DateStarted',
    c.DogovorNumber as 'DogovorNumber',
    N'рубли' as 'Currency',
    convert(varchar, dateadd(d, c.Period + long.period, c.DateStarted), 104) as 'OverdueDate',
    convert(varchar, dateadd(d, c.Period + 1 + long.period, c.DateStarted), 104) as 'DebtDate',
    b.Amount * 1.2 
    + b.PercentAmount 
    + b.CommisionAmount 
    + b.PenaltyAmount 
    + b.LongPrice
    + b.TransactionCosts 
    + (b.PercentAmount - lb.PercentAmount) 
    - 
    (
        select isnull(sum(cp.Amount + cp.PercentAmount + cp.CommissionAmount + cp.PenaltyAmount + cp.LongPrice + cp.TransactionCosts), 0)
        from dbo.CreditPayments cp 
        where cp.CreditId = c.Id 
            and cast(cp.DateCreated AS DATE) = dateadd(d, c.Period + long.period, c.DateStarted)
    ) as 'TotalDebtSum'
    ,bb.Amount 
    + bb.PercentAmount 
    + bb.CommisionAmount 
    + bb.PenaltyAmount 
    + bb.LongPrice 
    + bb.TransactionCosts as 'DebtForFirstOverdueDay'
from dbo.Debtors d 
left join dbo.Credits c ON c.Id = d.CreditId
outer apply 
(
    select isnull(sum(lcu.Period), 0) as period
    from dbo.LongCreditUnits lcu
    where lcu.CreditId = c.id
        and lcu.DateCreated < @endDate
) long
left join dbo.FrontendUsers u on u.Id = c.UserId
left join dbo.UserCards uc on uc.UserId = u.Id
left join dbo.UserAdminInformation a on a.UserId = u.Id
left join dbo.CreditBalances b on b.[Date] = dateadd(d, c.Period - 1 + long.period, c.DateStarted) 
    and b.CreditId = c.Id
left join dbo.CreditBalances lb on lb.[Date] = dateadd(d, c.Period - 2 + long.period, c.DateStarted) 
    and lb.CreditId = c.Id
left join dbo.CreditBalances bb on bb.[Date] = dateadd(d, c.Period + long.period, c.DateStarted) 
    and bb.CreditId = c.Id
where c.[Status] not in (5, 8)
    and dateadd(d, c.Period + long.period, c.DateStarted) between @startDate and @endDate
	and not (c.DatePaid is null or c.DatePaid > dateadd(d, c.Period + 1 + long.period, c.DateStarted))
