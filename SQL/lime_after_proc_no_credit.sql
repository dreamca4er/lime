select
  ucl.UserId
 ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
 ,fu.MobilePhone
 ,fu.EmailAddress
 ,th.StepId as currentStep
 ,th.stepname as currentTariff
 ,sh.Status
from dbo.CustomList cl
inner join dbo.UserCustomLists ucl on ucl.CustomlistID = cl.ID
inner join dbo.vw_TariffSteps ts on ts.StepID = ucl.CustomField1
inner join dbo.vw_TariffSteps tsNext on tsNext.TariffID = ts.TariffID
  and tsNext.StepOrder = ts.StepOrder + 2
join dbo.FrontendUsers fu on fu.Id = ucl.UserId
outer apply
(
  select top 1 
    uth.StepId
   ,tscurr.TariffName + '\' + tscurr.StepName as StepName
  from dbo.UserTariffHistory uth
  join dbo.vw_TariffSteps tscurr on tscurr.StepID = uth.StepId
  where uth.UserId = ucl.UserId
    and uth.IsLatest = 1
  order by uth.DateCreated desc
) th
cross apply 
(
  select top 1 ush.Status
  from dbo.UserStatusHistory ush
  where ush.UserId = ucl.UserId
    and ush.IsLatest = 1
    and ush.Status in (2, 11)
  order by ush.DateCreated desc
) sh
where cl.Type = 'ScUnbl_afterproc'
  and not exists (
    select 1 from dbo.Credits c
    where c.UserId = ucl.UserId
      and c.Status not in (5, 8)
      and c.DateCreated >= ucl.DateCreated
    )
  and ucl.CustomField1 is not null

