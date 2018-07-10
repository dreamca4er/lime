drop table if exists [dbo].[TariffUpdateList]
;

create table [dbo].[TariffUpdateList]  ( 
	[clientid]      	int not null primary key,
	[fio]           	nvarchar(100) not null,
	[Email]         	nvarchar(50) not null,
	[PhoneNumber]   	nvarchar(11) null,
	[DateRegistered]	date not null,
	[Passport]      	nvarchar(10) null,
	[substatusName] 	nvarchar(50) null,
	[STTariffName]  	nvarchar(20) null,
	[STTariffId]    	int null,
	[STStatus]          nvarchar(20),
	[LTTariffName]  	int null,
	[LTTariffId]    	nvarchar(20) null,
	[LTStatus]          nvarchar(20)
	)
GO

insert [dbo].[TariffUpdateList] 
select
    fu.id
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,fu.emailaddress
    ,fu.mobilephone
    ,cast(fu.DateRegistred as date) as DateRegistred
    ,uc.Passport
    ,ush.UserStatusKind
    ,st.STTariffName
    ,st.StepID
    ,case 
        when st.STIsActive = 1 then N'Текущий' 
        when st.STIsActive = 0 then N'Истекший' 
    end as STStatus
    ,lt.LTTariffName
    ,lt.StepID
    ,case 
        when lt.LTIsActive = 1 then N'Текущий' 
        when lt.LTIsActive = 0 then N'Истекший' 
    end as LTStatus 
from dbo.FrontendUsers fu
inner join dbo.UserCards uc on uc.UserId = fu.id
cross apply
(
    select top 1 
        ush.Status
        ,usk.Description as UserStatusKind
    from dbo.UserStatusHistory ush
    inner join dbo.EnumDescriptions usk on usk.Value = ush.Status
        and usk.Name = 'UserStatusKind'
    where ush.UserId = fu.id
        and ush.IsLatest = 1
    order by ush.DateCreated desc
) ush
outer apply
(
    select top 1 
        ts.TariffName + '/' + ts.StepName as STTariffName
        ,case when datediff(d, uth.DateCreated, getdate()) < t.ActivePeriod then 1 else 0 end as STIsActive
        ,ts.StepID
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
        and ts.TariffId != 4
    inner join dbo.Tariffs t on t.id = ts.TariffID
    where uth.UserId = fu.id
    order by 
        case when uth.IsLatest = 1 then 1 else 2 end
        ,uth.DateCreated desc
) st
outer apply
(
    select top 1 
        ts.TariffName + '/' + ts.StepName as LTTariffName
        ,case when datediff(d, uth.DateCreated, getdate()) < t.ActivePeriod then 1 else 0 end as LTIsActive
        ,ts.StepID
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
        and ts.TariffId = 4
    inner join dbo.Tariffs t on t.id = ts.TariffID
    where uth.UserId = fu.id
    order by 
        case when uth.IsLatest = 1 then 1 else 2 end
        ,uth.DateCreated desc
) lt
where uc.IsFraud = 0
    and uc.IsDied = 0
    and uc.IsCourtOrder = 0
    and not exists
        (
            select 1 from dbo.UserBlocksHistory ubh
            where ubh.UserId = fu.id
                and ubh.IsLatest = 1
7        )
    and not exists 
        (
            select 1 from dbo.Credits c
            where c.userid = fu.id
                and c.Status in (1, 3, 5)
        )
    and exists 
        (
            select 1 from dbo.UserTariffHistory uth
            where uth.UserId = fu.id
                and uth.IsLatest = 1
        )
    and ush.status in (9, 10, 11)


drop table if exists #tmp
;

select
    tu.clientid
    ,tu.Passport
    ,cast(replace(replace(us.UserStatusKind, '{"UserStatusKind":', ''), '}', '') as nvarchar(50)) as ClientStatus
    ,cast(replace(replace(c.CreditStatus, '{"CreditStatus":', ''), '}', '') as nvarchar(50)) as CreditStatus
into #tmp
from dbo.TariffUpdateLime tu
outer apply
(
    select distinct
        cs.Description as CreditStatus
    from dbo.Credits c
    inner join dbo.UserCards uc on uc.Passport = tu.Passport
    inner join dbo.EnumDescriptions cs on cs.Value = c.Status
        and cs.Name = 'CreditStatus'
    where c.UserId = uc.UserId
    for json auto, without_array_wrapper
) c(CreditStatus)
outer apply
(
    select top 1
        us.Description as UserStatusKind
    from dbo.UserCards uc
    inner join dbo.UserStatusHistory ush on ush.UserId = uc.UserId
        and ush.IsLatest = 1
    inner join dbo.EnumDescriptions us on us.Value = ush.Status
        and us.Name = 'UserStatusKind'
    where uc.Passport = tu.Passport
    for json auto, without_array_wrapper
) us(UserStatusKind)
where not exists 
    (
        select 1 from dbo.UserCards uc
        where uc.Passport = tu.Passport
            and (
                    uc.IsFraud = 1
                    or uc.IsDied = 1
                    or uc.IsCourtOrder = 1
                )
    )
    and not exists
    (
        select 1 from dbo.UserCards uc
        inner join dbo.Credits c on c.UserId = uc.UserId
        where uc.Passport = tu.Passport
            and c.Status in (1, 3, 5)
    )
;

delete tu
from dbo.TariffUpdateLime tu
left join #tmp t on t.ClientId = tu.ClientId
where t.ClientId is null
;

update tu 
set
    tu.ClientStatus = t.ClientStatus
    ,tu.CreditStatus = t.CreditStatus
from dbo.TariffUpdateLime tu
inner join #tmp t on t.ClientId = tu.ClientId
;

select top 1*
from dbo.UserCustomLists

insert dbo.UserCustomLists
(
    UserId, CustomlistID
)
select
    tu.ClientId
    ,43
from dbo.TariffUpdateList tu
inner join "BOR-LIME".Borneo.dbo.TariffUpdateKonga lk on lk.ClientId = tu.ClientId
inner join "MANGO-DB".Limezaim_Website.dbo.TariffUpdateKonga mk on mk.ClientId = tu.ClientId
/
drop table if exists dbo.TariffUpdateListFinal
;

CREATE TABLE [dbo].[TariffUpdateListFinal]  ( 
	[clientid]         	int NOT NULL,
	[fio]              	nvarchar(100) NOT NULL,
	[Email]            	nvarchar(50) NOT NULL,
	[PhoneNumber]      	nvarchar(11) NULL,
	[DateRegistered]   	date NOT NULL,
	[Passport]         	nvarchar(10) NULL,
	[substatusName]    	nvarchar(50) NULL,
	[STTariffName]     	nvarchar(20) NULL,
	[STTariffId]       	int NULL,
	[STStatus]         	nvarchar(20) NULL,
	[LTTariffName]     	nvarchar(20) NULL,
	[LTTariffId]       	int NULL,
	[LTStatus]         	nvarchar(20) NULL,
	[LimeCreditStatus] 	nvarchar(50) NULL,
	[KongaClientStatus]	nvarchar(50) NULL,
	[KongaCreditStatus]	nvarchar(50) NULL,
	[MangoClientStatus]	nvarchar(50) NULL,
	[MangoCreditStatus]	nvarchar(50) NULL,
	[score]            	numeric(17,6) NULL,
	[STNew]            	int NULL,
	[LTNew]            	int NULL,
	[STNewName]        	nvarchar(80) NULL,
	[LTNewName]        	nvarchar(80) NULL 
	)
GO

with t as 
(
select *
from
( 
    values
    (8, 0.49, 9, null, 0.55, null)
    ,(9, 0.49, 10, null, 0.55, null)
    ,(10, 0.49, 4, null, 0.55, null)
    ,(4, 0.49, 11, null, 0.55, null)
    ,(11, 0.49, 12, null, 0.55, null)
    ,(12, 0.49, 13, null, 0.55, null)
    ,(13, 0.49, 5, null, 0.55, null)
    ,(5, 0.49, 14, null, 0.55, null)
    ,(14, 0.49, null, null, 0.55, 24)
    ,(15, 0.49, null, null, 0.55, 25)
    ,(16, 0.49, null, null, 0.55, 26)
    ,(6, 0.49, null, null, 0.55, 27)
) t(STOld, STScore, STNew, LTOld, LTScore, LTNew)
)


,score as 
(
    select *
    from #Score
)

,pre as
(
    select
        tu.*
        ,c.CreditStatus as KongaCreditStatus
        ,lk.ClientStatus as LimeClientStatus
        ,lk.CreditStatus as LimeCreditStatus
        ,mk.ClientStatus as MangoClientStatus
        ,mk.CreditStatus as MangoCreditStatus
        ,s.Score
        ,case 
            when s.score >= t.STScore
                and st.StepOrder > sto.StepOrder 
            then t.STNew 
        end as STNew
        ,case 
            when s.score >= t.LTScore
                and lt.StepOrder > lto.StepOrder
            then t.LTNew 
        end as LTNew
        ,st.StepName as STNewName
        ,lt.StepName as LTNewName
    from dbo.TariffUpdateList tu
    inner join dbo.vw_GoodClientsForTariffUpdate gc on gc.ClientId = tu.ClientId 
    inner join "BOR-LIME".Borneo.dbo.TariffUpdateKonga lk on lk.ClientId = tu.ClientId
    inner join "MANGO-DB".Limezaim_Website.dbo.TariffUpdateKonga mk on mk.ClientId = tu.ClientId
    inner join #Score s on s.ClientId = tu.ClientId
    left join dbo.vw_TariffSteps sto on sto.StepId = tu.STTariffId
    left join dbo.vw_TariffSteps lto on lto.StepId = tu.LTTariffId
    left join t on (t.STOld = tu.STTariffId or t.STOld is null)
        and (t.LTOld = tu.LTTariffId or t.LTOld is null)
    left join dbo.vw_TariffSteps st on st.StepId = t.STNew
    left join dbo.vw_TariffSteps lt on lt.StepId = t.LTNew
    outer apply
    (
        select top 1 cs.Description as CreditStatus
        from dbo.Credits c
        inner join dbo.EnumDescriptions cs on cs.Value = c.Status
            and cs.Name = 'CreditStatus'
        where c.UserId = tu.ClientId
            and c.status != 8
        order by c.id
    ) c
)

insert dbo.TariffUpdateListFinal
select *
from pre
where STNew is not null or LTNew is not null

/

select * -- update uth set uth.IsLatest = 0
from dbo.TariffUpdateListFinal lf
inner join dbo.UserTariffHistory uth on uth.UserId = lf.clientid
inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
where ts.TariffID = 2
    and uth.IsLatest = 1
    and lf.STNew is not null
    and uth.StepId = lf.STTariffId
;

select * -- update uth set uth.IsLatest = 0
from dbo.TariffUpdateListFinal lf
inner join dbo.UserTariffHistory uth on uth.UserId = lf.clientid
inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
where ts.TariffID = 4
    and uth.IsLatest = 1
    and lf.LTNew is not null
    and uth.StepId = lf.LTTariffId
;

--insert dbo.UserTariffHistory (UserId, StepId, DateCreated, CreatedByUserId, RequestId, IsLatest)
select
    lf.clientid as UserId
    ,lf.STNew as StepId
    ,getdate() as DateCreated
    ,0 as CreatedByUserId
    ,0 as RequestId
    ,1 as IsLatest
from dbo.TariffUpdateListFinal lf
inner join dbo.UserTariffHistory uth on uth.UserId = lf.clientid
inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
where ts.TariffID = 2
    and uth.IsLatest = 1
    and lf.STNew is not null
    and uth.StepId = lf.STTariffId
;

--insert dbo.UserTariffHistory (UserId, StepId, DateCreated, CreatedByUserId, RequestId, IsLatest)
select
    lf.clientid as UserId
    ,lf.LTNew as StepId
    ,getdate() as DateCreated
    ,0 as CreatedByUserId
    ,0 as RequestId
    ,1 as IsLatest
from dbo.TariffUpdateListFinal lf
inner join dbo.UserTariffHistory uth on uth.UserId = lf.clientid
inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
where ts.TariffID = 4
    and uth.IsLatest = 1
    and lf.LTNew is not null
    and uth.StepId = lf.LTTariffId