select
    uc.UserId
    ,fu.Lastname
    ,fu.Firstname
    ,fu.Fathername
    ,fu.MobilePhone
    ,fu.EmailAddress
    ,usk.Description as status
    ,ts.TariffName + '\' + ts.StepName as tariff
from dbo.vw_UserStatuses us
inner join dbo.UserCards uc on uc.UserId = us.Id
inner join dbo.FrontendUsers fu on fu.Id = us.Id
inner join dbo.UserStatusKinds usk on usk.UserStatusKindId = us.State
left join dbo.UserTariffHistory uth on uth.UserId = us.Id
    and uth.IsLatest = 1
left join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
where us.State not in (6, 12)
    and uc.IsFraud = 0
    and uc.IsDied = 0
    and not exists 
                (
                    select 1 from dbo.UserBlocksHistory ub
                    where ub.UserId = us.id
                        and ub.IsLatest = 1
                )
    and MobilePhone not like '0%'
    