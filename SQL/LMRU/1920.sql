with ts as (
select
  StepID as id,
  TariffID,
  TariffName + '/' + StepName as Name,
  row_number() over (order by TariffID, StepOrder) as rn
from vw_TariffSteps
where TariffID != 3
)

,th as (
select
  UserId, 
  StepId,
  DateCreated
from UserTariffHistory tn
where tn.Id = (select max(tn2.id)
               from UserTariffHistory tn2
               join ts ts2 on ts2.Id = tn2.StepId
                 and ts2.TariffId in (1, 2)
               where tn2.UserId = tn.UserId
                 and tn2.DateCreated >= dateadd(dd, -14, '20170201')
                 and tn2.DateCreated < '20170601')
)

select 
  fu.id as UserId,
  fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio,
  fu.EmailAddress,
  fu.MobilePhone,
/*
  (select top 1 ush.Status
   from UserStatusHistory ush
   where ush.UserId = fu.id
     and ush.IsLatest = 1) as status,
*/
  ts.Name as oldTariff,
-------------------------
  (select ts2.Name
   from ts ts2
   where ts2.rn = ts.rn + 3) as newTariff
from FrontendUsers fu
join th tn on tn.UserId = fu.id
join ts ts on ts.Id = tn.StepId
where not exists (select 1 from UserTariffHistory uth
                  where uth.UserId = fu.id
                    and uth.StepId in (select ts.Id
                                       from ts ts 
                                       where ts.TariffId in (1, 2))
                    and uth.IsLatest = 1)
  and fu.id != 80808
  and not exists (select 1
                  from UserStatusHistory ush
                  where ush.UserId = fu.id
                    and ush.IsLatest = 1
                    and ush.Status in (3, 6))


/
with ts as (
select
  StepID as id,
  TariffID,
  TariffName + '/' + StepName as Name,
  row_number() over (order by TariffID, StepOrder) as rn
from vw_TariffSteps
where TariffID != 3
)

select
  fu.id as UserId,
  fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio,
  fu.EmailAddress,
  fu.MobilePhone,
  ts.Name as lastTariff,
  coalesce(
  (select ts2.Name
   from ts ts2
   where ts2.rn = coalesce(ts.rn, 3) + 3
     or ts.Name like 'исправление%' and ts2.rn = 6
), 'LimeUp/LimeUp9') as nextTariff
from FrontendUsers fu
left join UserTariffHistory tn on tn.UserId = fu.id
       and tn.Id = (select max(tn2.id)
                    from UserTariffHistory tn2
                    where tn2.UserId = tn.UserId)
left join ts ts on ts.Id = tn.StepId
where exists (select 1 from UserStatusHistory ush
              where ush.UserId = fu.id
                and ush.IsLatest = 1
                and ush.Status in (2, 11))
  and fu.DateRegistred >= '2017-01-01'