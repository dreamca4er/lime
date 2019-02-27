drop table if exists #konga
;

select 
    c.UserId as clientid
    , max(cast(c.DatePaid as date)) as LastCreditPaid
    , uc.Passport
into #konga
from dbo.Credits c
inner join dbo.UserCards uc on uc.UserId = c.UserId
inner join dbo.UserStatusHistory ush on ush.UserId = c.UserId
    and ush.IsLatest = 1
where not exists 
    (
        select 1 from dbo.br6384_oth oth
        where oth.Passport = uc.Passport
            and (oth.ProductStatus not like N'Погашен%' or 1 in (oth.IsDead, oth.IsFrauder, oth.IsCourtOrdered))
    )
    and uc.IsDied = 0
    and uc.IsCourtOrder = 0
    and uc.IsFraud = 0
    and ush.Status not in (6, 12)
group by c.UserId, uc.Passport
having max(cast(c.DatePaid as date)) <= '20190109'
    and avg(datediff(d, c.DateStarted, c.DatePaid)) > 5
    and count(case when c.Status in (1, 3, 5) then 1 end) = 0
;
/

drop table if exists #l
;

insert dbo.UserCustomLists
(
    CustomlistID, UserId, DateCreated 
)
select
    1005
    , fu.id as ClientId
    , getdate()
--    
--    , fu.Lastname
--    , fu.Firstname
--    , fu.Fathername
--    , fu.EmailAddress as Email
--    , fu.MobilePhone as PhoneNumber
--    , k.LastCreditPaid
--    , cast(fu.DateRegistred as date) as DateRegistred
--    , ustt.*
--    , ultt.*
--    , sr.*
--    , N'Погашен' as KongaProductStatus
--    , left(Mango.ProductStatus, 7) as MangoProductStatus
--    , left(Lime.ProductStatus, 7) as LimeProductStatus
--    , eq.LastEquiReqAge
--    , sc.Score
from #konga k
inner join dbo.FrontendUsers fu on fu.Id = k.ClientId
left join dbo.UserCustomLists ucl on ucl.UserId = fu.id
    and ucl.CustomlistID = 1004
--inner join dbo.br6384 sc on sc.UserId = fu.id
cross apply
(
    select top 1 
        ts.TariffName + '\' + ts.StepName as STTariff
        , ts.StepID as STTariffID
        , ts.StepOrder as STOrder
        , iif(dateadd(d, 30, cast(uth.DateCreated as date)) > getdate(), 1, 0) as STIsLatest
        , ts.StepMaxAmount as STMaxAmount
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    where ts.TariffID = 2
        and uth.UserId = k.ClientId
    order by uth.DateCreated desc
) ustt
outer apply
(
    select top 1 
        ts.TariffName + '\' + ts.StepName as LTTariff
        , ts.StepID as LTTariffID
        , ts.StepOrder as LTOrder
        , iif(dateadd(d, 30, cast(uth.DateCreated as date)) > getdate(), 1, 0) as LTIsLatest
        , ts.StepMaxAmount as LTMaxAmount
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    where ts.TariffID = 4
        and uth.UserId = k.ClientId
    order by uth.DateCreated desc
) ultt
outer apply
(
    select top 1 
        datediff(d, crr.Created, getdate()) as ScoreAge
        , sr.Score as OldScore
    from dbo.CreditRobotResults crr
    inner join dbo.MlScoringResponses sr on sr.CreditRobotResultId = crr.id
    where crr.UserId = k.ClientId
    order by crr.Created desc
) sr
outer apply
(
    select top 1 *
    from dbo.br6384_oth oth
    where oth.Passport = k.Passport
        and oth.Project = 'Mango'
    order by case when oth.ProductStatus is null then 2 else 1 end
) Mango
outer apply
(
    select top 1 *
    from dbo.br6384_oth oth
    where oth.Passport = k.Passport
        and oth.Project = 'Lime'
    order by case when oth.ProductStatus is null then 2 else 1 end
) Lime
outer apply
(
    select 
        datediff(d, max(er.DateCreated), getdate()) as LastEquiReqAge
    from dbo.EquifaxRequests er 
    where er.UserId = k.ClientId 
        and er.ResponseXml > ''
) eq
--inner join bi.TariffUpdateRools tur on tur.TariffId = ustt.STOrder
--    and tur.ProductType = 1
--    and sc.Score >= tur.ScoreFrom
--    and sc.Score < tur.ScoreTo
--inner join dbo.vw_tariffsteps tsn on tsn.StepOrder = tur.NewTariffId
--    and tsn.TariffId = 2
where not exists 
    (
        select 1 from dbo.credits cQ
        where c.UserId = fu.id
            and c.status in (1, 3, 5)
    )
    and eq.LastEquiReqAge <= 30
    and ucl.UserId is null
/

-- update ush set Islatest = 0, CreatedByUserId = 2, DateCreated = getdate()
from #l l
inner join dbo.UserStatusHistory ush on ush.UserId = l.ClientId
    and ush.IsLatest = 1
    
--insert dbo.UserStatusHistory (UserId,Status,IsLatest,DateCreated,CreatedByUserId)
select
    l.CLientId
    , 11 as Status
    , 1 as IsLatest
    , getdate()
    , 2 as CreatedByUserId
from #l l
;


select uai.State -- update uai set State = 11
from dbo.UserAdminInformation uai
inner join #l l on l.ClientId = uai.userid
;

select uth.*
-- update uth set Islatest = 0, CreatedByUserId = 2, DateCreated = getdate()
from #l l
inner join dbo.UserTariffHistory uth on uth.userid = l.ClientId
inner join dbo.vw_tariffSteps ts on ts.StepId = uth.StepId
    and ts.TariffId = 2
where uth.IsLatest = 1
;

--insert into dbo.UserTariffHistory (UserId,StepId,DateCreated,CreatedByUserId,RequestId,IsLatest)
select
    ClientId as UserId
    , NewStepid as StepId
    , getdate() as DateCreated
    , 2 as CreatedByUserId
    , 0 as RequestId
    , 1 as IsLatest
from #l
;

-- update uai set uai.StepName = ts.TariffName + '\' + ts.StepName
from dbo.UserAdminInformation uai
inner join #l l on l.ClientId = uai.userid
inner join dbo.vw_TariffSteps ts on ts.StepID = l.NewStepid
/
select ucl.* -- update ucl set CustomField1 = NewStepId
from dbo.UserCustomLists ucl
inner join #l l on l.ClientId = ucl.userId
where ucl.CustomlistID = 1004
