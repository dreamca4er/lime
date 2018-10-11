drop table if exists #c
;

select
    b.*
    ,fu.Lastname
    ,fu.Firstname
    ,fu.Fathername
    ,fu.mobilephone
    ,fu.emailaddress
    ,ush.Status
    ,st.id as STNewId
    ,lt.id as LTNewId
    ,st.MaxAmount as STStepMaxAmount
    ,st."Percent" as STPercent
    ,lt.MaxAmount as LTStepMaxAmount
    ,lt."Percent" as LTPercent
    ,ost.UserTariffHistoryId as STUserTariffHistoryId
    ,olt.UserTariffHistoryId as LTUserTariffHistoryId
into #c
from dbo.br3321 b
inner join dbo.FrontendUsers fu on fu.id = b.ClientId
left join dbo.TariffSteps st on b.STNew = st.Name
    and st.TariffID = 2
left join dbo.TariffSteps lt on b.LTNew = lt.Name
    and lt.TariffID = 4
outer apply
(
    select top 1 ush.Status
    from dbo.UserStatusHistory ush
    where ush.UserId = b.ClientId
        and ush.IsLatest = 1
    order by ush.DateCreated desc
) ush
outer apply
(
    select
        uth.id as UserTariffHistoryId
        ,uth.StepId
        ,ts.StepOrder
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    where uth.UserId = b.ClientId
        and uth.IsLatest = 1
        and ts.TariffID = 2
) ost
outer apply
(
    select 
        uth.id as UserTariffHistoryId
        ,uth.StepId
        ,ts.StepOrder
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    where uth.UserId = b.ClientId
        and uth.IsLatest = 1
        and ts.TariffID = 4
) olt
where not exists
    (
        select 1 from dbo.Credits c
        where c.userId = b.ClientId
            and c.Status in (1, 3, 5)
    )
    and ush.status not in (6, 12)
;
/
select * -- update uth set IsLatest = 0
from #c c
inner join dbo.UserTariffHistory uth on uth.id = c.STUserTariffHistoryId
where STNewId is not null
;

select * -- update uth set IsLatest = 0
from #c c
inner join dbo.UserTariffHistory uth on uth.id = c.LTUserTariffHistoryId
where LTNewId is not null
;

--insert dbo.UserTariffHistory
--(
--    UserId,StepId,DateCreated,CreatedByUserId,RequestId,IsLatest
--)
select
    ClientId as UserId
    ,STNewId as StepId
    ,getdate() as DateCreated
    ,1 as CreatedByUserId
    ,0 as RequestId
    ,1 as IsLatest
from #c
where STNewId is not null
;

--insert dbo.UserTariffHistory
--(
--    UserId,StepId,DateCreated,CreatedByUserId,RequestId,IsLatest
--)
select
    ClientId as UserId
    ,LTNewId as StepId
    ,getdate() as DateCreated
    ,1 as CreatedByUserId
    ,0 as RequestId
    ,1 as IsLatest
from #c
where LTNewId is not null
;

select * -- update ush set IsLatest = 0
from #c c
inner join dbo.UserStatusHistory ush on ush.UserId = c.ClientId
    and ush.IsLatest = 1
where c.Status != 11
;

--insert UserStatusHistory
--(
--    UserId,Status,IsLatest,DateCreated,CreatedByUserId
--)
select
    ClientId as UserId
    ,11 as Status
    ,1 as IsLatest
    ,getdate() as DateCreated
    ,1 as CreatedByUserId
from #c c
where c.Status != 11 
;
/
select 
    uai.userid
    , uai.StepName
    ,isnull(ost.StepName + case when olt.StepName is not null then ', ' else '' end, '')
    + isnull(olt.StepName, '') -- update uai set uai.StepName = isnull(ost.StepName + case when olt.StepName is not null then ', ' else '' end, '') + isnull(olt.StepName, '')
from dbo.UserAdminInformation uai
inner join #c b on b.ClientId = uai.UserId
outer apply
(
    select
        uth.id as UserTariffHistoryId
        ,ts.TariffName + '/' + ts.StepName as StepName
        ,uth.StepId
        ,ts.StepOrder
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    where uth.UserId = b.ClientId
        and uth.IsLatest = 1
        and ts.TariffID = 2
) ost
outer apply
(
    select 
        uth.id as UserTariffHistoryId
        ,ts.TariffName + '/' + ts.StepName as StepName
        ,uth.StepId
        ,ts.StepOrder
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    where uth.UserId = b.ClientId
        and uth.IsLatest = 1
        and ts.TariffID = 4
) olt
/

select 
    ClientId
    ,Lastname
    ,Firstname
    ,Fathername
    ,mobilephone
    ,emailaddress
    ,STNew
    ,STStepMaxAmount
    ,STPercent
    ,LTNew 
    ,LTStepMaxAmount
    ,LTPercent
from #c
/

select
    b.*
    ,st."Order" as STStepOrder
    ,lt."Order" as LTStepOrder
    ,ost.*
    ,olt.*
from dbo.br3321 b
inner join
(
    select userid
    from dbo.UserTariffHistory
    where DateCreated = '2018-09-20 11:17:31.033'
    union
    select userid
    from dbo.UserTariffHistory
    where DateCreated = '2018-09-20 11:17:25.783'
) th on th.userid = b.ClientId
left join dbo.TariffSteps st on b.STNew = st.Name
    and st.TariffID = 2
left join dbo.TariffSteps lt on b.LTNew = lt.Name
    and lt.TariffID = 4
outer apply
(
    select top 1
        ts.StepOrder
        ,uth.DateCreated
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    where uth.UserId = b.ClientId
        and uth.IsLatest = 0
        and ts.TariffID = 2
    order by uth.DateCreated desc
) ost
outer apply
(
    select top 1
        ts.StepOrder
        ,uth.DateCreated
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    where uth.UserId = b.ClientId
        and uth.IsLatest = 0
        and ts.TariffID = 4
    order by uth.DateCreated desc
) olt
where ((ost.StepOrder > st."Order" and st."Order" is not null and datediff(d, ost.DateCreated, getdate()) < 50)
    or (olt.StepOrder > lt."Order" and lt."Order" is not null and datediff(d, olt.DateCreated, getdate()) < 50))
