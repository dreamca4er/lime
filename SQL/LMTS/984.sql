drop table if exists #lmts984
;

select
    uth.UserId
    ,ts.StepID
    ,ts.TariffName + '\' + ts.StepName as stepName
    ,tsnext.StepID as nextStepID
    ,tsnext.TariffName + '\' + tsnext.StepName as nextStepName
into #lmts984
from dbo.vw_UserStatuses us
inner join dbo.UserTariffHistory uth on uth.UserId = us.Id
    and uth.IsLatest = 1
inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
left join dbo.vw_TariffSteps tsnext on ts.TariffID = tsnext.TariffID
    and (tsnext.StepOrder = ts.StepOrder + 2
            or ts.StepOrder + 2 > 12
                and tsnext.StepOrder = 12)
where us.State = 11
    and ts.TariffID = 2
    and ts.StepID != 8
;

--insert into dbo.userCustomLists
select 
    12
    ,userid
    ,getdate()
    ,nextStepID
    ,2
from #lmts984

select *
from dbo.userCustomLists
where CustomlistID = 12

select *
from dbo.CustomList
where id = 12

--exec dbo.cusp_UserListUnblockAndSetTariff 12
