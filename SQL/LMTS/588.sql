with users as 
(
    select distinct
        c.UserId
    from dbo.CreditPaymentSchedules cps
    inner join dbo.Credits c on c.id = cps.CreditId
    where cps.Date >= cast(getdate() as date)
        and cps.Date <= dateadd(d, 2, cast(getdate() as date))
)

,getStep as 
(
    select distinct
        fu.id as userid
        ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
        ,fu.mobilephone
        ,fu.emailaddress
        ,ts.TariffType
        ,ts.TariffName + '\' + ts.stepName as currentStep
        ,tsNext.TariffName + '\' + tsNext.stepName as nextStep
        ,ts.StepID
        ,tsNext.StepID as nextStepId
    from dbo.FrontendUsers fu
    inner join dbo.UserStatusHistory ush on ush.userid = fu.id
        and ush.IsLatest = 1
    inner join dbo.UserTariffHistory uth on uth.UserId = fu.Id
        and uth.IsLatest = 1
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    left join dbo.vw_TariffSteps tsNext on tsNext.TariffID = ts.TariffID
        and (tsNext.StepOrder = ts.StepOrder + 3
                or ts.TariffType = 1 and ts.StepOrder >= 9 and tsNext.StepOrder = 12
                or ts.TariffType = 2 and ts.StepOrder >= 7 and tsNext.StepOrder = 9) 
    where fu.id in (select userid from users)
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
                        where ucl.CustomlistID in (55, 56, 57, 58)
                            and ucl.UserId = fu.id
                    )
)
/*
insert into dbo.UserCustomLists
select
    59
    ,userid
    ,getdate()
    ,nextStepId
    ,2
from getStep
where TariffType = 2
/

*/

/

with users as 
(
select distinct
    userid
from dbo.UserStatusHistory ush
cross apply
(
    select top 1
        ushPre.DateCreated
        ,ushPre.status
    from dbo.UserStatusHistory ushPre
    where ushPre.UserId = ush.UserId
        and ushPre.DateCreated < ush.DateCreated
        and ushPre.id < ush.id
    order by ushPre.DateCreated desc, ushPre.id desc
) ushPre
where ush.Status = 2
    and not exists
                (
                    select 1 from dbo.UserBlocksHistory ubh
                    where ubh.UserId = ush.userid
                        and ubh.IsLatest = 1
                )
    and not exists 
                (
                    select 1 from dbo.UserCustomLists ucl
                    where ucl.CustomlistID in (55, 56, 57, 58)
                        and ucl.UserId = ush.userid
                )
    and ush.DateCreated >= '20170920'
    and ushPre.status = 11
)

,getStep as 
(
    select distinct
        fu.id as userid
        ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
        ,fu.mobilephone
        ,fu.emailaddress
        ,uthST.STStep
        ,STStepNext
        ,uthLT.LTStep
        ,LTStepNext
        ,uthST.StepId as nextStepIdST
        ,uthLT.StepId as nextStepIdLT
    from dbo.FrontendUsers fu
    inner join dbo.UserStatusHistory ush on ush.userid = fu.id
        and ush.IsLatest = 1
    outer apply
    (
        select top 1
            uthPre.StepId
            ,tsPre.TariffName + + '\' + tsPre.stepName as STStep
            ,tsNext1.TariffName + + '\' + tsNext1.stepName as STStepNext
        from dbo.UserTariffHistory uthPre
        inner join dbo.vw_TariffSteps tsPre on tsPre.stepId = uthPre.StepId
            and tsPre.TariffType = 1
        left join dbo.vw_TariffSteps tsNext1 on tsNext1.TariffID = tsPre.TariffID
            and (tsNext1.StepOrder = tsPre.StepOrder + 3
                    or tsPre.TariffType = 1 and tsPre.StepOrder >= 9 and tsNext1.StepOrder = 12
                    or tsPre.TariffType = 2 and tsPre.StepOrder >= 7 and tsNext1.StepOrder = 9) 
        where uthPre.UserId = fu.Id
        order by uthPre.DateCreated desc
    ) uthST
    outer apply
    (
        select top 1
            uthPre.StepId
            ,tsPre.TariffName + + '\' + tsPre.stepName as LTStep
            ,tsNext1.TariffName + + '\' + tsNext1.stepName as LTStepNext
        from dbo.UserTariffHistory uthPre
        inner join dbo.vw_TariffSteps tsPre on tsPre.stepId = uthPre.StepId
            and tsPre.TariffType = 2
        left join dbo.vw_TariffSteps tsNext1 on tsNext1.TariffID = tsPre.TariffID
            and (tsNext1.StepOrder = tsPre.StepOrder + 3
                    or tsPre.TariffType = 1 and tsPre.StepOrder >= 9 and tsNext1.StepOrder = 12
                    or tsPre.TariffType = 2 and tsPre.StepOrder >= 7 and tsNext1.StepOrder = 9)
        where uthPre.UserId = fu.Id
        order by uthPre.DateCreated desc
    ) uthLT
    where fu.id in (select userid from users)
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
                        where ucl.CustomlistID in (55, 56, 57, 58, 59, 60)
                            and ucl.UserId = fu.id
                    )
)

select
    userid
    ,nextStepIdST
from getStep
where nextStepIdST is not null

union

select
    userid
    ,nextStepIdLT
from getStep
where nextStepIdLT is not null