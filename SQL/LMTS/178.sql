select
    c.UserId
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,fu.emailaddress
    ,fu.mobilephone
    ,sop.Date as scheduledpayment
from dbo.Credits c
inner join dbo.FrontendUsers fu on fu.Id = c.UserId
inner join dbo.ScheduleOfPayments sop on sop.CreditId = c.id
    and sop.Date between '20170826' and '20170830'
where c.Status = 1
    and c.TariffId = 4

/

select distinct
    c.UserId
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,fu.emailaddress
    ,fu.mobilephone
from dbo.Credits c
inner join dbo.FrontendUsers fu on fu.Id = c.UserId
where c.Status = 3
    and c.TariffId = 4