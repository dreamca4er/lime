drop table if exists dbo.br993Mango
;

with ClientsList1 as
(
    select 
        fu.id as ClientId
        ,uc.Passport
    from dbo.FrontendUsers fu
    inner join dbo.UserCards uc on uc.UserId = fu.id
    cross apply
    (
        select top 1 ush.Status
        from dbo.UserStatusHistory ush
        where ush.UserId = fu.id
            and ush.IsLatest = 1
        order by ush.DateCreated desc
    ) ush
    where uc.IsFraud = 0
        and uc.IsDied = 0
        and uc.IsCourtOrder = 0
        and not exists
            (
                select 1 from dbo.UserBlocksHistory ubh
                where ubh.UserId = fu.id
                    and ubh.IsLatest = 1
            )
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
        and ush.status not in (6, 12)
    
    union
    
    select 
        fu.id as ClientId
        ,uc.Passport
    from dbo.FrontendUsers fu
    inner join dbo.UserCards uc on uc.UserId = fu.id
    cross apply
    (
        select top 1 ush.Status
        from dbo.UserStatusHistory ush
        where ush.UserId = fu.id
            and ush.IsLatest = 1
        order by ush.DateCreated desc
    ) ush
    where uc.IsFraud = 0
        and uc.IsDied = 0
        and uc.IsCourtOrder = 0
        and not exists
            (
                select 1 from dbo.UserBlocksHistory ubh
                where ubh.UserId = fu.id
                    and ubh.IsLatest = 1
            )
        and not exists 
            (
                select 1 from dbo.Credits c
                where c.userid = fu.id
                    and c.Status in (1, 3, 5)
            )
        and not exists 
            (
                select 1 from dbo.UserTariffHistory uth
                where uth.UserId = fu.id
                    and uth.IsLatest = 1
            )
        and exists 
            (
                select 1 from dbo.UserTariffHistory uth
                inner join dbo.TariffSteps ts on ts.id = uth.StepId
                where uth.UserId = fu.id
                    and uth.IsLatest = 0
                    and dateadd(d, ts.MaxPeriod, uth.DateCreated) >= dateadd(d, -90, getdate())
            )
        and ush.status not in (6, 12)
            
    union
    
    select 
        fu.id as ClientId
        ,uc.Passport
    from dbo.FrontendUsers fu
    inner join dbo.UserCards uc on uc.UserId = fu.id
    cross apply
    (
        select top 1 ush.Status
        from dbo.UserStatusHistory ush
        where ush.UserId = fu.id
            and ush.IsLatest = 1
        order by ush.DateCreated desc
    ) ush
    where uc.IsFraud = 0
        and uc.IsDied = 0
        and uc.IsCourtOrder = 0
        and not exists
            (
                select 1 from dbo.UserBlocksHistory ubh
                where ubh.UserId = fu.id
                    and ubh.IsLatest = 1
            )
        and not exists 
            (
                select 1 from dbo.Credits c
                where c.userid = fu.id
                    and c.Status in (1, 3, 5)
            )
        and exists 
            (
                select 1 from dbo.Credits c
                where c.userid = fu.id
                    and c.Status = 2
                    and datediff(d, c.DatePaid, getdate()) + 1 between 10 and 120
            )
        and ush.status not in (6, 12)
)

,ClientsList2 as 
(
    select
        fu.id as ClientId
        ,uc.Passport
    from dbo.FrontendUsers fu
    inner join dbo.UserCards uc on uc.UserId = fu.id
    cross apply
    (
        select top 1 ush.Status
        from dbo.UserStatusHistory ush
        where ush.UserId = fu.id
            and ush.IsLatest = 1
        order by ush.DateCreated desc
    ) ush
    where uc.IsFraud = 0
        and uc.IsDied = 0
        and uc.IsCourtOrder = 0
        and not exists
            (
                select 1 from dbo.UserBlocksHistory ubh
                where ubh.UserId = fu.id
                    and ubh.IsLatest = 1
            )
        and not exists 
            (
                select 1 from dbo.Credits c
                where c.userid = fu.id
            )
        and not exists 
            (
                select 1 from dbo.UserTariffHistory uth
                where uth.UserId = fu.id
            )
        and not exists 
            (
                select 1 from dbo.EquifaxRequests er
                where er.UserId= fu.id
            )
        and ush.status not in (6, 12)
)

,ClientsList3 as 
(
    select top 0
        fu.id as ClientId
        ,uc.Passport
    from dbo.FrontendUsers fu
    inner join dbo.UserCards uc on uc.UserId = fu.id
)
    
,ClientsList4 as 
(
    select top 0
        fu.id as ClientId
        ,uc.Passport
    from dbo.FrontendUsers fu
    inner join dbo.UserCards uc on uc.UserId = fu.id
)

,ClientsList5 as 
(
    select 
        fu.id as ClientId
        ,uc.Passport
    from dbo.FrontendUsers fu
    inner join dbo.UserCards uc on uc.UserId = fu.id
    cross apply
    (
        select top 1 ush.Status
        from dbo.UserStatusHistory ush
        where ush.UserId = fu.id
            and ush.IsLatest = 1
        order by ush.DateCreated desc
    ) ush
    where uc.IsFraud = 0
        and uc.IsDied = 0
        and uc.IsCourtOrder = 0
        and not exists
            (
                select 1 from dbo.UserBlocksHistory ubh
                where ubh.UserId = fu.id
                    and ubh.IsLatest = 1
            )
        and not exists 
            (
                select 1 from dbo.Credits c
                where c.userid = fu.id
                    and c.Status in (1, 3, 5)
            )
        and exists 
            (
                select 1 from dbo.Credits c
                where c.userid = fu.id
                    and c.Status = 2
                    and datediff(d, c.DatePaid, getdate()) > 120
            )
        and not exists 
            (
                select 1 from dbo.Credits c
                where c.userid = fu.id
                    and c.Status = 2
                    and datediff(d, c.DatePaid, getdate()) <= 120
            )
        and exists 
            (
                select 1 from dbo.UserTariffHistory uth
                inner join dbo.TariffSteps ts on ts.id = uth.StepId
                where uth.UserId = fu.id
                    and uth.IsLatest = 0
                    and dateadd(d, ts.MaxPeriod, uth.DateCreated) >= dateadd(d, -90, getdate())
            )
        and not exists 
            (
                select 1 from dbo.UserTariffHistory uth
                where uth.UserId = fu.id
                    and uth.IsLatest = 1
            )
       and ush.status not in (6, 12)
)


select distinct
    clientid
    ,Passport
into dbo.br993Mango
from ClientsList5

create clustered index IX_dbo_br993Mango_clientid on dbo.br993Mango(clientid)
;

/

drop table if exists #clFullList
;

select *
into #clFullList
from
(
    select
        clientid
        ,passport collate SQL_Latin1_General_CP1_CI_AS
    from dbo.br993Mango

    union

    select
        null as clientid
        ,passport collate SQL_Latin1_General_CP1_CI_AS
    from "BOR-LIME".Borneo.dbo.br993Lime l
    where isnull(passport, replicate('0', 10)) not in (replicate('0', 10), '')
        and not exists
            (
                select 1
                from dbo.br993Mango m
                where m.passport = l.passport
                collate SQL_Latin1_General_CP1_CI_AS
            )
    

    union

    select
        null as clientid
        ,passport collate SQL_Latin1_General_CP1_CI_AS
    from "KONGA-DB".LimeZaim_Website.dbo.br993Konga k
    where isnull(passport, replicate('0', 10)) not in (replicate('0', 10), '')
        and not exists
            (
                select 1
                from dbo.br993Mango m
                where m.passport = k.passport
                collate SQL_Latin1_General_CP1_CI_AS
            )
) c (clientid, passport
)

create index IX_passport_clientid_clFullList on #clFullList(passport, clientid)
/

drop table if exists #MangoList
;

   
select *
into #MangoList
from 
(
    select
        fu.id as clientid
        ,case when cl.clientid is not null then 1 end as MangoNeeded
        ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
        ,fu.mobilephone
        ,fu.emailaddress
        ,uc.Passport collate SQL_Latin1_General_CP1_CI_AS as Passport
    from dbo.FrontendUsers fu
    inner join dbo.UserCards uc on uc.UserId = fu.id
    inner join #clFullList cl on cl.clientid = uc.userid
    
    union
    
    select
        fu.id as clientid
        ,case when cl.clientid is not null then 1 end as MangoNeeded
        ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
        ,fu.mobilephone
        ,fu.emailaddress
        ,uc.Passport collate SQL_Latin1_General_CP1_CI_AS as Passport
    from dbo.FrontendUsers fu
    inner join dbo.UserCards uc on uc.UserId = fu.id
    inner join #clFullList cl on cl.clientid is null 
        and cl.passport = uc.passport collate SQL_Latin1_General_CP1_CI_AS
) c


drop table if exists dbo.br993
;

select
    k.*
    ,st.STTariffName
    ,st.STIsActive
    ,lt.LTTariffName
    ,lt.LTIsActive
    ,ush.UserStatus as MangoUserStatus
    ,isnull(c.CreditStatus, N'Не было кредитов') as MangoCreditStatus
    ,c.OverdueDays as MangoOverdueDays
into dbo.br993
from #MangoList k
outer apply
(
    select top 1 ed.Description as UserStatus
    from dbo.UserStatusHistory ush
    inner join dbo.EnumDescriptions ed on ed.Value = ush.Status
        and ed.Name = 'UserStatusKind'
    where ush.UserId = k.clientid
        and ush.IsLatest = 1
    order by ush.DateCreated desc
) ush
outer apply
(
    select top 1 
        ed.Description as CreditStatus
        ,case when csh.status = 3 then datediff(d, csh.DateStarted, getdate()) + 1 end as OverdueDays
    from dbo.Credits c
    inner join dbo.EnumDescriptions ed on ed.Value = c.Status
        and ed.Name = 'CreditStatus'
    outer apply
    (
        select top 1 
            csh.Status
            ,csh.DateStarted
        from dbo.CreditStatusHistory csh
        where csh.CreditId = c.id
        order by csh.DateStarted desc
    ) csh
    where c.UserId = k.clientid
        and c.Status != 8
    order by 
        case when c.Status in (1, 3) then 1 else 2 end
        ,c.DatePaid desc
) c
outer apply
(
    select top 1 
        ts.TariffName + '/' + ts.StepName as STTariffName
        ,uth.IsLatest as STIsActive
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
        and ts.TariffId != 4
    where uth.UserId = k.clientid
    order by 
        case when uth.IsLatest = 1 then 1 else 2 end
        ,uth.DateCreated desc
) st
outer apply
(
    select top 1 
        ts.TariffName + '/' + ts.StepName as LTTariffName
        ,uth.IsLatest as LTIsActive
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
        and ts.TariffId = 4
    where uth.UserId = k.clientid
    order by 
        case when uth.IsLatest = 1 then 1 else 2 end
        ,uth.DateCreated desc
) lt

create index IX_br993_passport on dbo.br993(Passport) where MangoNeeded = 1
create clustered index IX_br993_passport_client on dbo.br993(Passport, clientid desc)


/

drop table if exists dbo.br993Fin
;

drop table if exists #l
;

select *
into #l 
from "BOR-LIME".Borneo.dbo.br993 l
;

drop table if exists #k
;

select *
into #k
from  "KONGA-DB".LimeZaim_Website.dbo.br993 k
;
 
create index IX_k_passport on #k(passport)
;

create index IX_l_passport on #l(passport)
;


drop table if exists dbo.br993Fin
;


select
    b.*
    ,l.LimeUserStatus
    ,l.LimeCreditStatus
    ,l.LimeOverdueDays
    ,k.KongaUserStatus
    ,k.KongaCreditStatus
    ,k.KongaOverdueDays
into dbo.br993Fin
from dbo.br993 b
outer apply
(
    select top 1 *
    from #k k 
    where k.passport = b.passport 
) k
outer apply
(
    select top 1 *
    from #l l 
    where l.passport = b.passport 
) l
where b.MangoNeeded = 1
/

/*
select * --select top 10 *
from dbo.br993Fin
*/
select
    f.*
    ,s.score
from dbo.br993Fin f
left join dbo.br993Score s on f.clientid = s.userid