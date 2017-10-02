select distinct
    fu.id as userid
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,fu.mobilephone
    ,fu.emailaddress
    ,ts.TariffName + '\' + ts.stepName as currentStep
    ,tsNext.TariffName + '\' + tsNext.stepName as nextStep
from dbo.FrontendUsers fu
inner join dbo.UserStatusHistory ush on ush.userid = fu.id
    and ush.IsLatest = 1
inner join dbo.UserTariffHistory uth on uth.UserId = fu.Id
    and uth.IsLatest = 1
inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    and ts.TariffType = 1
left join dbo.vw_TariffSteps tsNext on tsNext.TariffID = ts.TariffID
    and (tsNext.StepOrder = ts.StepOrder + 3
            or ts.StepOrder >= 9
                and tsNext.StepOrder = 12)
where ush.Status = 11

/

select distinct
    fu.id as userid
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,fu.mobilephone
    ,fu.emailaddress
    ,ts.TariffName + '\' + ts.stepName as currentStep
/*
    ,tsNext.StepOrder
    ,tsNext.TariffName + '\' + tsNext.stepName as nextStep
*/
from dbo.FrontendUsers fu
inner join dbo.UserStatusHistory ush on ush.userid = fu.id
    and ush.IsLatest = 1
inner join dbo.UserTariffHistory uth on uth.UserId = fu.Id
    and uth.IsLatest = 1
inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    and ts.TariffType = 1
    and ts.StepOrder >= 9
/* 
left join dbo.vw_TariffSteps tsNext on tsNext.TariffID = ts.TariffID
    and (tsNext.StepOrder = ts.StepOrder + 3
            or ts.StepOrder >= 9
                and tsNext.StepOrder = 12)
*/
where ush.Status = 11
    and exists 
                (
                    select 1 from dbo.Credits c
                    where c.UserId = fu.id
                        and c.Status = 2
                )

/

select distinct
    fu.id as userid
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,fu.mobilephone
    ,fu.emailaddress
    ,ts.TariffName + '\' + ts.stepName as currentStep
/*
    ,tsNext.StepOrder
    ,tsNext.TariffName + '\' + tsNext.stepName as nextStep
*/
from dbo.FrontendUsers fu
inner join dbo.UserStatusHistory ush on ush.userid = fu.id
    and ush.IsLatest = 1
inner join dbo.UserTariffHistory uth on uth.UserId = fu.Id
    and uth.IsLatest = 1
inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    and ts.TariffType = 2
/* 
left join dbo.vw_TariffSteps tsNext on tsNext.TariffID = ts.TariffID
    and (tsNext.StepOrder = ts.StepOrder + 3
            or ts.StepOrder >= 9
                and tsNext.StepOrder = 12)
*/
where ush.Status = 11
    and exists 
                (
                    select 1 from dbo.Credits c
                    where c.UserId = fu.id
                        and c.Status = 2
                )