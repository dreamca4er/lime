with part1 as 
(
    select distinct
        fu.id as userid
        ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
        ,fu.mobilephone
        ,fu.emailaddress
        ,ts.TariffName + '\' + ts.stepName as currentStep
        ,tsNext.TariffName + '\' + tsNext.stepName as nextStep
        ,tsNext.StepID as nextStepId
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
        and left(fu.mobilephone, 1) = '9'
        and not exists
                    (
                        select 1 from dbo.UserBlocksHistory ubh
                        where ubh.UserId = fu.id
                            and ubh.IsLatest = 1
                    )
        and not exists 
                    (
                        select 1 from dbo.UserCustomLists ucl
                        where ucl.CustomlistID = 55
                            and ucl.UserId = fu.id
                    )
)
insert into dbo.UserCustomLists
select
    56
    ,userid
    ,getdate()
    ,nextStepId
    ,2
from part1

select *
from dbo.UserCustomLists
where CustomlistID = 56

select *
from dbo.CustomList


exec cusp_UserListUnblockAndSetTariff 56
/

with part2 as 
(
    select distinct
        fu.id as userid
        ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
        ,fu.mobilephone
        ,fu.emailaddress
        ,ts.TariffName + '\' + ts.stepName as currentStep
    from dbo.FrontendUsers fu
    inner join dbo.UserStatusHistory ush on ush.userid = fu.id
        and ush.IsLatest = 1
    inner join dbo.UserTariffHistory uth on uth.UserId = fu.Id
        and uth.IsLatest = 1
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
        and ts.TariffType = 1
        and ts.StepOrder >= 9
    where ush.Status = 11
        and left(fu.mobilephone, 1) = '9'
        and exists 
                    (
                        select 1 from dbo.Credits c
                        where c.UserId = fu.id
                            and c.Status = 2
                    )
        and not exists
                    (
                        select 1 from dbo.UserBlocksHistory ubh
                        where ubh.UserId = fu.id
                            and ubh.IsLatest = 1
                    )
        and not exists 
                    (
                        select 1 from dbo.UserCustomLists ucl
                        where ucl.CustomlistID = 55
                            and ucl.UserId = fu.id
                    )
)

-- Даем LimeUp8
insert into dbo.UserCustomLists
select
    57
    ,userid
    ,getdate()
    ,27
    ,2
from part2


/

with part3 as 
(
    select distinct
        fu.id as userid
        ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
        ,fu.mobilephone
        ,fu.emailaddress
        ,ts.TariffName + '\' + ts.stepName as currentStep
        ,tsNext.Stepid as nextStepId
        ,tsNext.TariffName + '\' + tsNext.stepName as nextStep
    from dbo.FrontendUsers fu
    inner join dbo.UserStatusHistory ush on ush.userid = fu.id
        and ush.IsLatest = 1
    inner join dbo.UserTariffHistory uth on uth.UserId = fu.Id
        and uth.IsLatest = 1
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
        and ts.TariffType = 2
    left join dbo.vw_TariffSteps tsNext on tsNext.TariffID = ts.TariffID
        and (tsNext.StepOrder = ts.StepOrder + 1)
    --            or ts.StepOrder >= 9
    --                and tsNext.StepOrder = 12)
    where ush.Status = 11
        and left(fu.mobilephone, 1) = '9'
        and exists 
                    (
                        select 1 from dbo.Credits c
                        where c.UserId = fu.id
                            and c.Status = 2
                            and c.TariffId = 4
                    )
        and not exists
                    (
                        select 1 from dbo.UserBlocksHistory ubh
                        where ubh.UserId = fu.id
                            and ubh.IsLatest = 1
                    )
        and not exists 
                    (
                        select 1 from dbo.UserCustomLists ucl
                        where ucl.CustomlistID in (55, 56, 57)
                            and ucl.UserId = fu.id
                    )
)

insert into dbo.UserCustomLists
select
    58
    ,userid
    ,getdate()
    ,nextStepId
    ,2
from part3
/

select *
from dbo.UserCustomLists
where CustomlistID = 58