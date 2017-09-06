select 
    c.UserId
    --,c.id as creditid
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,fu.emailaddress
    ,fu.mobilephone
/*
    ,cast(coalesce(
            min(case when sop.Date >= cast(getdate() as date) then sop.Date end)
            ,max(sop.Date)
    ) as date) as nextPaymentDate
*/
from dbo.Credits c
inner join dbo.FrontendUsers fu on fu.Id = c.UserId
left join dbo.ScheduleOfPayments sop on sop.CreditId = c.id
where c.TariffId = 4
    and c.status = 3
    --and c.UserId != 124713
group by 
    c.UserId
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '')
    ,fu.emailaddress
    ,fu.mobilephone
/*
group by c.UserId
having count(*) > 1

select *
from CreditStatusHistory
where CreditId = 207634

select *
from CreditStatusHistory
where CreditId = 227670

select *
from ScheduleOfPayments
where creditid = 218159


*/