select
  c.UserId
 ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
 ,fu.EmailAddress
 ,fu.MobilePhone
 ,max(c.DatePaid) as DatePaid
from dbo.credits c
join dbo.FrontendUsers fu on fu.id = c.UserId
where c.TariffId = 4
group by c.UserId
 ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '')
 ,fu.EmailAddress
 ,MobilePhone
having count(*) = 1
  and max(c.Status) = 2

/
with cInfo as (
select
  c.UserId
 ,c.Amount
 ,DateStarted
 ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
 ,fu.EmailAddress
 ,fu.MobilePhone
 ,row_number() over (partition by c.UserId order by c.datestarted desc) as rn
from dbo.Credits c
join dbo.FrontendUsers fu on fu.id = c.UserId
where c.TariffId = 4
  and c.status = 2
)

select 
  c.UserId
 ,c.fio
 ,c.EmailAddress
 ,c.MobilePhone
 ,count(*) as credCount
 ,sum(case when c.rn = 1 then c.Amount else null end) as lastCredSum
 ,(select top 1 ts.StepName
   from dbo.UserTariffHistory uth
   join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
   where ts.TariffType = 2
     and uth.UserId = c.userid
   order by uth.DateCreated desc
  ) as currentTariff
 ,max(c.DateStarted) as lastCredStarted
from cInfo c
group by c.UserId
 ,c.fio
 ,c.EmailAddress
 ,c.MobilePhone
having count(*) > 1
