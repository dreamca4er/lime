select
    cast(c.DateCreated as date) as contractDate
    ,cast(c.DateStarted as date) as creditDate
    ,cast(dateadd(d, c.Period, c.DateStarted) as date) as contractEndDate
    ,c.Amount
    ,c.DogovorNumber
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,c."Percent"
    ,cast(c.DatePaid as date) as datePaid
    ,edu.Description as creditStatus
    ,mw.Description as moneyWay
from dbo.Credits c
inner join dbo.FrontendUsers fu on fu.Id = c.UserId
inner join dbo.EnumDescriptions edu on edu.Value = c.Status
    and edu.Name = 'CreditStatus'
left join dbo.EnumDescriptions mw on mw.Value = c.Way
    and mw.Name = 'MoneyWay'
where c.Status != 8
    and c.DateStarted >= '20160901'
    and c.DateStarted < '20171001'
