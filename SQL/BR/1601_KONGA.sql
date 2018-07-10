drop table if exists #LimeWithCredit
;

drop table if exists #MangoWithCredit
;

select
    c.ClientId
    ,c.Passport
into #LimeWithCredit
from "BOR-LIME".Borneo.prd.vw_product p
inner join "BOR-LIME".Borneo.client.vw_client c on p.clientid = c.clientid
where p.status in (3, 4, 7)
;

create index IX_LimeWithCredit_Passport on #LimeWithCredit(Passport)
;

select
    fu.id as ClientId
    ,uc.Passport
into #MangoWithCredit
from "Mango-DB".Limezaim_Website.dbo.FrontendUsers fu
inner join "Mango-DB".Limezaim_Website.dbo.UserCards uc on uc.userid = fu.id
inner join "Mango-DB".Limezaim_Website.dbo.Credits c on c.UserId = fu.id
    and c.Status = 1
;
/
drop table if exists #cl
;

drop table if exists #cl2
;

drop table if exists #cl3
;


with clients as 
(
select
    uth.id
    ,uth.UserId as clientid
    ,case when ts.TariffID = 2 then 1 else 2 end as ProductType
    ,uth.StepId as TariffId
    ,ts.TariffName + '/' + ts.StepName as TariffName
    ,uth.IsLatest
    ,ts.StepOrder
    ,cast(uth.DateCreated as date) as TariffStart
    ,null as TariffEnd
    ,N'Есть тариф, нет кредитов' as ClientType
from dbo.UserTariffHistory uth
inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    and (ts.TariffID = 2 and ts.StepOrder in (7,8,9,10,11,12)
        or ts.TariffID = 4 and ts.StepOrder in (1,2,3,4,5,6,7))
inner join dbo.Tariffs t on t.Id = ts.TariffID
where uth.islatest = 1
    and ts.TariffID in (2, 4)
    and not exists 
            (
                select 1 from dbo.Credits c
                where c.UserId = uth.UserId
                    and c.Status in (1, 3, 5)
            )
    and not exists 
            (
                select 1 from dbo.Credits c
                where c.UserId = uth.UserId
                    and c.Status = 2
                    and datediff(d, c.DatePaid, getdate()) > 10
            )
    and datediff(d, dateadd(d, t.ActivePeriod, uth.DateCreated), getdate()) < -3

union

select
    uth.id
    ,uth.UserId as clientid
    ,case when ts.TariffID = 2 then 1 else 2 end as ProductType
    ,uth.StepId as TariffId
    ,ts.TariffName + '/' + ts.StepName as TariffName
    ,uth.IsLatest
    ,ts.StepOrder
    ,cast(uth.DateCreated as date) as TariffStart
    ,null as TariffEnd
    ,N'Тариф истекает' as ClientType
from dbo.UserTariffHistory uth
inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    and (ts.TariffID = 2 and ts.StepOrder in (7,8,9,10,11,12)
        or ts.TariffID = 4 and ts.StepOrder in (1,2,3,4,5,6,7))
inner join dbo.Tariffs t on t.Id = ts.TariffID
where uth.islatest = 1
    and ts.TariffID in (2, 4)
    and datediff(d, dateadd(d, t.ActivePeriod, uth.DateCreated), getdate()) >= -3
    and not exists 
            (
                select 1 from dbo.Credits c
                where c.UserId = uth.UserId
                    and c.Status in (1, 3, 5)
            )    
    
union

select
    uth.id
    ,uth.UserId as clientid
    ,case when ts.TariffID = 2 then 1 else 2 end as ProductType
    ,uth.StepId as TariffId
    ,ts.TariffName + '/' + ts.StepName as TariffName
    ,uth.IsLatest
    ,ts.StepOrder
    ,cast(uth.DateCreated as date) as TariffStart
    ,dateadd(d, t.ActivePeriod + 1, cast(uth.DateCreated as date)) as TariffEnd
    ,N'Тариф истек в последние 45 дней' as ClientType   
from dbo.UserTariffHistory uth
inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    and (ts.TariffID = 2 and ts.StepOrder in (7,8,9,10,11,12)
        or ts.TariffID = 4 and ts.StepOrder in (1,2,3,4,5,6,7))
inner join dbo.Tariffs t on t.Id = ts.TariffID
where uth.islatest = 0
    and ts.TariffID in (2, 4)
    and datediff(d, dateadd(d, t.ActivePeriod, uth.DateCreated), getdate()) <= 45
    and not exists
            (
                select 1 from dbo.UserTariffHistory uth1
                inner join dbo.vw_TariffSteps ts1 on ts1.StepID = uth1.StepId
                inner join dbo.Tariffs t1 on t1.Id = ts1.TariffID
                where uth1.UserId = uth.UserId
                    and datediff(d, dateadd(d, t1.ActivePeriod, uth1.DateCreated), getdate()) <= 45
                    and uth1.DateCreated > uth.DateCreated
                    
            )
    and not exists 
            (
                select 1 from dbo.UserTariffHistory uth1
                where uth1.UserId = uth.UserId
                    and uth1.IsLatest = 1
            )
    and not exists 
            (
                select 1 from dbo.Credits c
                where c.UserId = uth.UserId
                    and c.Status in (1, 3, 5)
            )            
)

select
    c.clientid
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,fu.emailaddress as Email
    ,fu.mobilephone as PhoneNumber
    ,max(case when c.ProductType = 1 then c.TariffName end) as STTariffName
    ,max(case when c.ProductType = 1 then c.TariffStart end) as STTariffStart
    ,max(case when c.ProductType = 1 then c.TariffEnd end) as STTariffEnd
    ,max(case when c.ProductType = 1 then c.ClientType end) as STClientType
    ,max(case when c.ProductType = 2 then c.TariffName end) as LTTariffName
    ,max(case when c.ProductType = 2 then c.TariffStart end) as LTTariffStart
    ,max(case when c.ProductType = 2 then c.TariffEnd end) as LTTariffEnd
    ,max(case when c.ProductType = 2 then c.ClientType end) as LTClientType
from clients c
inner join dbo.FrontendUsers fu on fu.Id = c.clientid
inner join dbo.UserCards uc on uc.UserId = fu.id
where uc.IsFraud = 0
    and uc.IsDied = 0
    and uc.IsCourtOrder = 0
group by 
    c.clientid
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '')
    ,fu.emailaddress
    ,fu.mobilephone


/
,upped as 
(
select 
    c.*
    ,2 as NewTariffType
    ,ts.StepID as NewTariffId
    ,ts.TariffName + '/' + ts.StepName as NewTariffName
from clients c
inner join dbo.vw_TariffSteps ts on ts.TariffID = 4
    and ts.StepOrder = 
                        case 
                        when c.StepOrder = 7 then 5
                        when c.StepOrder in (8, 9) then 6
                        when c.StepOrder = 10 then 7
                        when c.StepOrder in (11, 12) then 8
                        end     
where c.ProductType = 1
    and not exists 
            (
                select 1 from clients c1
                where c1.clientid = c.clientid
                    and c1.ProductType = 2
                    and c1.StepOrder >= ts.StepOrder
                    and c1.islatest = 1
            )

union

select 
    c.*
    ,2 as NewTariffType
    ,ts.StepID as NewTariffId
    ,ts.TariffName + '/' + ts.StepName as NewTariffName
from clients c
inner join dbo.vw_TariffSteps ts on ts.TariffID = 4
    and ts.StepOrder = (select min(t) from (values (c.StepOrder + 4), (8)) as v(t)) 
where c.ProductType = 2
)

,fin as 
(
select *
from upped
where NewTariffType = 1

union

select *
from upped u
where NewTariffType = 2
    and not exists 
            (
                select 1 from upped u2
                where u2.clientid = u.clientid
                    and u2.NewTariffType = 2
                    and (u2.NewTariffId > u.NewTariffId or u2.NewTariffId = u.NewTariffId and u2.id > u.id)
            )
)

select distinct
    f.clientid
    ,uc.Passport
    ,f.NewTariffId
    ,f.NewTariffType
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,fu.mobilephone
    ,fu.emailaddress
    ,f.TariffName
    ,f.NewTariffName
    ,ts.StepMaxAmount
    ,tst."Percent" as PercentPerDay
    ,replace(replace((
        select distinct ClientType
        from clients c
        where c.clientid = f.clientid
        for json auto, without_array_wrapper
    ), '{"ClientType":"', ''), '"}', '') as ClientType 
into #cl
from fin f
inner join dbo.FrontendUsers fu on fu.Id = f.clientid
inner join dbo.vw_TariffSteps ts on ts.StepID = f.NewTariffId
inner join dbo.TariffSteps tst on tst.Id = ts.StepID
outer apply
(
    select top 1 
        uc.Passport
        ,uc.IsFraud
        ,uc.IsDied
        ,uc.IsCourtOrder
    from dbo.UserCards uc
    where uc.UserId = fu.id
) uc
where isnull(uc.IsFraud, 0) = 0
    and isnull(uc.IsDied, 0) = 0
    and isnull(uc.IsCourtOrder, 0) = 0
;

create clustered index IX_cl_clientid on #cl(clientid)
;

with LimeStatus as 
(
    SELECT 0 AS id,N'Создан' AS name
    UNION ALL
    SELECT 1 AS id,N'Отменён' AS name
    UNION ALL
    SELECT 2 AS id,N'Не подтверждён' AS name
    UNION ALL
    SELECT 3 AS id,N'Активен' AS name
    UNION ALL
    SELECT 4 AS id,N'Просрочен' AS name
    UNION ALL
    SELECT 5 AS id,N'Погашен' AS name
    UNION ALL
    SELECT 6 AS id,N'На цессии' AS name
    UNION ALL
    SELECT 7 AS id,N'На реструктуризации' AS name
)

select
    cl.*
    ,p.ProductStatusName as KongaProductStatus
    ,l.LimeProductStatus
    ,m.MangoProductStatus
into #cl2
from #cl cl
outer apply
(
    select top 1 ls.Name as LimeProductStatus
    from dbo.br841lime l
    inner join LimeStatus ls on ls.id = l.status
    where l.Passport = cl.Passport
) l
outer apply
(
    select top 1 ed.Description as MangoProductStatus
    from dbo.br841mango m
    inner join dbo.EnumDescriptions ed on ed.name = 'CreditStatus'
        and ed.value = m.status
    where m.Passport = cl.Passport
) m
outer apply
(
    select top 1 
        c.id as ProductId
        ,c.status as ProductStatus
        ,ed.Description as ProductStatusName
        ,max(csh.DateStarted) as ProductStatusStart
    from dbo.Credits c
    inner join dbo.EnumDescriptions ed on ed.Value = c.Status
        and ed.Name = 'CreditStatus'
    inner join dbo.CreditStatusHistory csh on csh.CreditId = c.id
    where c.userid = cl.clientid
        and c.status != 8
    group by c.id, c.status, ed.Description, c.DateStarted
    order by c.DateStarted desc
) p
where (p.ProductStatusName is null or p.ProductStatusName = N'Погашенный')
    and (l.LimeProductStatus is null or l.LimeProductStatus = N'Погашен')
    and (m.MangoProductStatus is null or m.MangoProductStatus = N'Погашенный')

;
select c.*
into #cl3
from #cl2 c
outer apply
(
    select top 1 ush.Status, ed.Description as Statusname
    from dbo.UserStatusHistory ush
    inner join dbo.EnumDescriptions ed on ed.Value = ush.Status
        and ed.Name = 'UserStatuskind'
    where ush.UserId = c.clientid
        and ush.IsLatest = 1
) ush
where ush.Status not in (6, 12)
    and not exists 
            (
                select 1 from UserTariffHistory uth
                inner join dbo.TariffSteps ts on ts.id = uth.StepId
                    and ts.TariffId = 4
                where uth.UserId = c.clientid
                    and uth.islatest = 1
                    and uth.StepId = c.NewtariffId
            )
;
/
select c.* -- update uth set islatest = 0
from #cl3 c
inner join UserTariffHistory uth on uth.UserId = c.clientid
    and uth.IsLatest = 1
inner join dbo.TariffSteps ts on ts.id = uth.StepId
    and ts.TariffId = 4

insert into UserTariffHistory
(
    UserId, StepId, DateCreated, CreatedByUserId, RequestId, IsLatest
)
select
    clientid
    ,NewTariffId
    ,getdate()
    ,2
    ,0
    ,1
from #cl3

select
    clientid
    ,isnull(uth.STName + ', ', '') + c.newtariffName -- update uai set uai.Stepname = isnull(uth.STName + ',', '') + c.newtariffName 
from #cl3 c
inner join dbo.UserAdminInformation uai on uai.UserId = c.clientid
outer apply
(
    select top 1 
        ts.TariffName + '/' + ts.StepName as STName
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
        and ts.TariffId = 2
    where uth.UserId = c.clientid
        and uth.IsLatest = 1
) uth


/

select *
from CustomList

insert into UserCustomLists
select
    33
    ,clientid
    ,'20180515 15:00'
    ,NewtariffId
    ,null
from #cl3
/
select
    uc.userid
    ,uc.Passport
    ,c.Status
from dbo.UserCards uc
cross apply
(
    select top 1
        c.Status
    from dbo.Credits c
    where uc.UserId = c.UserId
        and c.Status != 8
    order by c.DateStarted desc
) c


create table dbo.br841lime
(
    clientId int
    ,Passport nvarchar(20)
    ,status int
)


create table dbo.br841mango
(
    clientId int
    ,Passport nvarchar(20)
    ,status int
)


create clustered index IX_br841lime_clientId on dbo.br841lime(clientId)
create clustered index IX_br841mango_clientId on dbo.br841mango(clientId)
/
select *
from dbo.UserCards
where Passport = '4612783884'

select *
from dbo.Credits
where UserId = 621895