with list as 
(
select
    l.*
    ,fu.id as userid
--    ,uth.TariffID
    ,uth.stepName
--    ,uth.StepOrder
--    ,uth.stepid
--    ,tsnext.stepId as nextStepId
    ,tsnext.TariffName + '\' + tsnext.StepName as nextStepName
from lmts531 l
join dbo.FrontendUsers fu on fu.MobilePhone = l.mobile
outer apply
(
    select 
        uth.StepId
        ,ts.TariffName + '\' + ts.StepName as stepName
        ,ts.TariffID
        ,ts.StepOrder
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    where uth.UserId = fu.id
        and uth.IsLatest = 1
) uth
left join dbo.vw_TariffSteps tsnext on tsnext.TariffID = isnull(uth.TariffID, 2)
    and tsnext.StepOrder = isnull(uth.StepOrder, 0) + 2
    or uth.StepOrder >= 11
        and tsnext.StepOrder = 12
where fu.id != 108879 -- исправление
)

/*
insert into dbo.UserCustomLists
select 
    17
    ,l.userid
    ,getdate()
    ,nextStepId
    ,2
from list l
*/
select
    l.*
from dbo.UserCustomLists ucl
inner join list l on l.userid = ucl.userid
where ucl.CustomlistID = 17
    and ucl.CustomField2 is null
/--exec cusp_UserListUnblockAndSetTariff 17