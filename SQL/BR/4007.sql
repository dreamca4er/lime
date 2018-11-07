drop table if exists  #pre
;

select
    uth.Id as UserTariffHistoryId
    ,uth.UserId
    ,tsNew.StepID
    ,tsNew.StepMaxAmount
    ,tsNew.TariffName + '\' + tsNew.StepName as TariffName
into #pre
from dbo.UserTariffHistory uth
inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    and ts.TariffID = 2
inner join dbo.vw_TariffSteps tsNew on tsNew.TariffID = 2
    and tsNew.StepOrder =
        case  
            when ts.StepOrder between 1 and 4 then ts.StepOrder + 3
            when ts.StepOrder between 5 and 10 then ts.StepOrder + 2
            when ts.StepOrder = 1 then ts.StepOrder + 1
            else ts.StepOrder
        end
inner join dbo.UserCards uc on uc.UserId = uth.UserId
where uth.IsLatest = 1
    and uc.IsFraud = 0
    and uc.IsDied = 0
    and not exists 
        (
            select 1 from dbo.Credits c
            where c.UserId = uth.UserId
                and c.Status in (1, 3)
        )
    and exists 
        (
            select 1 from dbo.UserStatusHistory ush
            where ush.IsLatest = 1
                and ush.UserId = uth.UserId
                and ush.Status = 11
        )
;
/
select uth.* -- update uth set uth.IsLatest = 0, DateLastUpdated = getdate(), LastUpdatedByUserId = 0
from #pre p
inner join dbo.UserTariffHistory uth on uth.id = p.UserTariffHistoryId
;
/
--insert dbo.UserTariffHistory
(
    UserId,StepId,DateCreated,CreatedByUserId,RequestId,IsLatest
)
select
    UserId
    ,StepId
    ,getdate() as DateCreated
    ,0 as CreatedByUserId
    ,0 as RequestId
    ,1 as IsLatest
from #pre
;

select uai.* -- update uai set StepName = p.TariffName
from #pre p
inner join dbo.UserAdminInformation uai on uai.userid = p.userid
/

insert dbo.UserCustomLists
(
    CustomlistID,UserId,DateCreated,CustomField1
)
select
    40 as CustomlistID
    ,UserId
    ,'20181015'
    ,StepId
from #pre
;

/

select
    uth.UserId
    ,fu.Lastname
    ,fu.Firstname
    ,fu.Fathername
    ,fu.EmailAddress
    ,fu.MobilePhone
    ,ts.TariffName + '\' + ts.StepName as TariffName
    ,ts.StepMaxAmount
from dbo.UserTariffHistory uth
inner join dbo.FrontendUsers fu on fu.Id = uth.UserId
inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    and ts.TariffID = 2
inner join dbo.UserCards uc on uc.UserId = uth.UserId
where uth.IsLatest = 1
    and uc.IsFraud = 0
    and uc.IsDied = 0
    and not exists 
        (
            select 1 from dbo.Credits c
            where c.UserId = uth.UserId
                and c.Status in (1, 3)
        )
    and exists 
        (
            select 1 from dbo.UserStatusHistory ush
            where ush.IsLatest = 1
                and ush.UserId = uth.UserId
                and ush.Status = 11
        )
        