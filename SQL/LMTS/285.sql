with nocred as 
(
    select distinct
        fu.id
        ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
        ,fu.emailaddress
        ,fu.mobilephone
        ,edu.Description as currentStatus
        ,N'Не было кредитов' as creditStatus
        ,uth.TariffName + '\' + uth.StepName as currentStep
    --    ,uth.StepOrder
        ,isnull(tsNext.TariffName + '\' + tsNext.StepName, 'Lime\Gold') as nexrTariffName
        ,isnull(tsNext.StepMaxAmount, 12000) as nextmaxAmount
    --    ,tsNext.steporder as nextstepOrder
        ,coalesce(tsNext.stepid, 6) as nextstepId
    from dbo.FrontendUsers fu
    inner join dbo.UserStatusHistory ush on ush.UserId = fu.id
        and ush.IsLatest = 1
    inner join dbo.EnumDescriptions edu on edu.Value = ush.Status
        and edu.name = 'UserStatusKind'
    outer apply
    (
        select top 1 
            ts.StepID
            ,ts.TariffName
            ,ts.StepName
            ,ts.StepOrder
        from dbo.UserTariffHistory uth
        inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
        where uth.UserId = fu.id
            and uth.IsLatest = 1
            and ts.TariffID = 2
        order by uth.DateCreated desc
    ) uth
    left join dbo.vw_TariffSteps tsNext on tsNext.StepOrder = isnull(uth.StepOrder, 0) + 2
        and tsNext.TariffID = 2
    where ush.Status = 11
        and not exists (
                        select 1 
                        from dbo.credits c
                        where c.UserId = fu.Id
                            and c.Status != 8
                        )
        and fu.DateRegistred >= '20170829'
        and not exists (
                        select 1 from dbo.UserCustomLists ucl
                        where ucl.UserId = fu.id
                            and ucl.CustomlistID in (49, 50)
                    )
)

--insert into UserCustomLists
select
    51 as CustomlistID
    ,id as UserId
    ,getdate()
    ,nextstepId
    ,2 as CustomField2
from nocred

--exec [dbo].[cusp_UserListUnblockAndSetTariff] 51

/
with closed as 
(
    select distinct
        fu.id
        ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
        ,fu.emailaddress
        ,fu.mobilephone
        ,edu.Description as currentStatus
        ,N'Погашенный' as creditStatus
        ,uth.TariffName + '\' + uth.StepName as currentStep
    --    ,uth.StepOrder
        ,isnull(tsNext.TariffName + '\' + tsNext.StepName, 'Lime\Gold') as nexrTariffName
        ,isnull(tsNext.StepMaxAmount, 12000) as nextmaxAmount
    --    ,tsNext.steporder as nextstepOrder
        ,coalesce(tsNext.stepid, 6) as nextstepId
    from dbo.FrontendUsers fu
    inner join dbo.UserStatusHistory ush on ush.UserId = fu.id
        and ush.IsLatest = 1
    inner join dbo.EnumDescriptions edu on edu.Value = ush.Status
        and edu.name = 'UserStatusKind'
    outer apply
    (
        select top 1 
            ts.StepID
            ,ts.TariffName
            ,ts.StepName
            ,ts.StepOrder
        from dbo.UserTariffHistory uth
        inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
        where uth.UserId = fu.id
            and uth.IsLatest = 1
            and ts.TariffID = 2
        order by uth.DateCreated desc
    ) uth
    left join dbo.vw_TariffSteps tsNext on tsNext.StepOrder = isnull(uth.StepOrder, 0) + 2
        and tsNext.TariffID = 2
    where ush.Status = 11
        and exists (
                        select 1 
                        from dbo.credits c
                        where c.UserId = fu.Id
                            and c.Status = 2
                            and c.DatePaid >= '20170829'
                        )
        and not exists (
                        select 1 from dbo.UserCustomLists ucl
                        where ucl.UserId = fu.id
                            and ucl.CustomlistID in (49, 50)
                    )
)

--insert into UserCustomLists
select
    52 as CustomlistID
    ,id as UserId
    ,getdate()
    ,nextstepId
    ,2 as CustomField2
from closed
/
with toUpd as 
(
    select
        uth.UserId
    from UserCustomLists ucl
    inner join UserTariffHistory uth on uth.UserId = ucl.UserId
        and uth.IsLatest = 1
        and uth.StepId = 12
        and exists (
                        select 1 from UserTariffHistory uthpre
                        inner join dbo.vw_TariffSteps ts on ts.StepID = uthpre.StepId
                            and ts.TariffID = 2
                        where uthpre.DateCreated < uth.DateCreated
                            and uthpre.StepId in (6, 16)
                            and uthpre.UserId = uth.UserId
                            and uthpre.id = (
                                                select max(id) from UserTariffHistory uth1
                                                inner join dbo.vw_TariffSteps ts2 on ts2.StepID = uth1.StepId
                                                   and ts2.TariffID = 2
                                                 where uth1.UserId = uth.userid
                                                    and uth1.DateCreated < uth.DateCreated
                                            )
                    )
    where ucl.CustomlistID = 52
)

/*
update ucl
set CustomField1 = 6, CustomField2 = 2
*/
--select *
from dbo.UserCustomLists ucl
inner join toUpd on toUpd.userid = ucl.userid
    and ucl.CustomlistID = 52
/

select *
from dbo.UserCustomLists
where CustomlistID in (51, 52)

/

    select distinct
        fu.id
        ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
        ,fu.emailaddress
        ,fu.mobilephone
        ,edu.Description as currentStatus
        ,N'Не было кредитов' as creditStatus
        ,uth.TariffName + '\' + uth.StepName as currentStep
    --    ,uth.StepOrder
        ,isnull(tsNext.TariffName + '\' + tsNext.StepName, 'Lime\Gold') as nexrTariffName
        ,isnull(tsNext.StepMaxAmount, 12000) as nextmaxAmount
    --    ,tsNext.steporder as nextstepOrder
        ,coalesce(tsNext.stepid, 6) as nextstepId
    from dbo.FrontendUsers fu
    inner join dbo.UserStatusHistory ush on ush.UserId = fu.id
        and ush.IsLatest = 1
    inner join dbo.EnumDescriptions edu on edu.Value = ush.Status
        and edu.name = 'UserStatusKind'
    outer apply
    (
        select top 1 
            ts.StepID
            ,ts.TariffName
            ,ts.StepName
            ,ts.StepOrder
        from dbo.UserTariffHistory uth
        inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
        where uth.UserId = fu.id
            and uth.IsLatest = 1
            and ts.TariffID = 2
        order by uth.DateCreated desc
    ) uth
    left join dbo.vw_TariffSteps tsNext on tsNext.StepOrder = isnull(uth.StepOrder, 0) + 2
        and tsNext.TariffID = 2
    where ush.Status not in ()
        and not exists (
                        select 1 
                        from dbo.credits c
                        where c.UserId = fu.Id
                            and c.Status != 8
                        )
        and fu.DateRegistred >= '20170829'
        and not exists (
                        select 1 from dbo.UserCustomLists ucl
                        where ucl.UserId = fu.id
                            and ucl.CustomlistID in (49, 50)
                    )