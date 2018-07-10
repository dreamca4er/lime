drop table if exists #KongaWithCredit
;

drop table if exists #MangoWithCredit
;

select
    fu.id as ClientId
    ,uc.Passport
into #KongaWithCredit
from "Konga-DB".Limezaim_Website.dbo.FrontendUsers fu
inner join "Konga-DB".Limezaim_Website.dbo.UserCards uc on uc.userid = fu.id
inner join "Konga-DB".Limezaim_Website.dbo.Credits c on c.UserId = fu.id
    and c.Status in (1, 3)
;

create index IX_KongaWithCredit_Passport on #KongaWithCredit(Passport)
;

select
    fu.id as ClientId
    ,uc.Passport
into #MangoWithCredit
from "Mango-DB".Limezaim_Website.dbo.FrontendUsers fu
inner join "Mango-DB".Limezaim_Website.dbo.UserCards uc on uc.userid = fu.id
inner join "Mango-DB".Limezaim_Website.dbo.Credits c on c.UserId = fu.id
    and c.Status in (1, 3)
;

create index IX_MangoWithCredit_Passport on #MangoWithCredit(Passport)
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
    th.id
    ,th.clientid
    ,th.ProductType
    ,th.TariffId
    ,th.TariffName
    ,th.IsLatest
    ,th.CreatedOn as TariffStart
    ,cast(null as date) as TariffEnd 
    ,N'Есть тариф, нет кредитов' as ClientType
from client.vw_TariffHistory th
left join prd.ShortTermTariff stt on stt.Id = th.TariffId
    and th.ProductType = 1
left join prd.LongTermTariff ltt on ltt.Id = th.TariffId
    and th.ProductType = 2
left join client."Identity" i on i.ClientId = th.ClientId
where IsLatest = 1
    and not exists 
            (
                select 1 from prd.vw_Product p
                where p.ClientId = th.ClientId
                    and p.status in (0, 2, 3, 4, 7)
            )
    and (th.ProductType = 1 and th.TariffId in (7,8,9,10,11,12)
        or th.ProductType = 2 and th.TariffId in (1,2,3,4,5,6,7))
    and datediff(d, dateadd(d, isnull(stt.ActivePeriod, ltt.ActivePeriod), th.CreatedOn), getdate()) < -3

union

select
    th.id
    ,th.clientid
    ,th.ProductType
    ,th.TariffId
    ,th.TariffName
    ,th.IsLatest
    ,th.CreatedOn as TariffStart
    ,cast(null as date) as TariffEnd
    ,N'Тариф истекает' as ClientType
from client.vw_TariffHistory th
left join prd.ShortTermTariff stt on stt.Id = th.TariffId
    and th.ProductType = 1
left join prd.LongTermTariff ltt on ltt.Id = th.TariffId
    and th.ProductType = 2
where datediff(d, dateadd(d, isnull(stt.ActivePeriod, ltt.ActivePeriod), th.CreatedOn), getdate()) >= -3
    and th.IsLatest = 1
    and (th.ProductType = 1 and th.TariffId in (7,8,9,10,11,12)
        or th.ProductType = 2 and th.TariffId in (1,2,3,4,5,6,7))    
    and not exists 
            (
                select 1 from prd.vw_Product p
                where p.ClientId = th.ClientId
                    and p.status in (0, 2, 3, 4, 7)
            )        

union

select
    th.id
    ,th.clientid
    ,th.ProductType
    ,th.TariffId
    ,th.TariffName
    ,th.IsLatest
    ,th.CreatedOn as TariffStart
    ,cast(dateadd(d, isnull(stt.ActivePeriod, ltt.ActivePeriod) + 1, th.CreatedOn) as date) as TariffEnd
    ,N'Тариф истек в последние 45 дней' as ClientType
from client.vw_TariffHistory th
left join prd.ShortTermTariff stt on stt.Id = th.TariffId
    and th.ProductType = 1
left join prd.LongTermTariff ltt on ltt.Id = th.TariffId
    and th.ProductType = 2
where datediff(d, dateadd(d, isnull(stt.ActivePeriod, ltt.ActivePeriod), th.CreatedOn), getdate()) <= 45
    and islatest = 0
    and not exists
            (
                select 1 from client.vw_TariffHistory th1
                left join prd.ShortTermTariff stt1 on stt1.Id = th1.TariffId
                    and th1.ProductType = 1
                left join prd.LongTermTariff ltt1 on ltt1.Id = th1.TariffId
                    and th1.ProductType = 2
                where th1.ClientId = th.ClientId
                    and datediff(d, dateadd(d, isnull(stt1.ActivePeriod, ltt1.ActivePeriod), th1.CreatedOn), getdate()) <= 45
                    and th1.CreatedOn > th.CreatedOn
            )
    and not exists
            (
                select 1 from client.vw_TariffHistory th1
                where th1.ClientId = th.ClientId
                    and th1.IsLatest = 1
            )
    and (th.ProductType = 1 and th.TariffId in (7,8,9,10,11,12)
        or th.ProductType = 2 and th.TariffId in (1,2,3,4,5,6,7))
    and not exists 
            (
                select 1 from prd.vw_Product p
                where p.ClientId = th.ClientId
                    and p.status in (0, 2, 3, 4, 7)
            )
)

select
    cl.clientid
    ,cl.fio
    ,cl.Email
    ,cl.PhoneNumber
--    ,c.ProductType
--    ,c.TariffId
--    ,c.IsLatest
    ,max(case when c.ProductType = 1 then c.TariffName end) as STTariffName
    ,max(case when c.ProductType = 1 then c.TariffStart end) as STTariffStart
    ,max(case when c.ProductType = 1 then c.TariffEnd end) as STTariffEnd
    ,max(case when c.ProductType = 1 then c.ClientType end) as STClientType
    ,max(case when c.ProductType = 2 then c.TariffName end) as LTTariffName
    ,max(case when c.ProductType = 2 then c.TariffStart end) as LTTariffStart
    ,max(case when c.ProductType = 2 then c.TariffEnd end) as LTTariffEnd
    ,max(case when c.ProductType = 2 then c.ClientType end) as LTClientType
from clients c
inner join client.vw_client cl on c.clientid = cl.clientid
where cl.status != 3
    and cl.IsDead = 0
    and cl.IsCourtOrdered = 0
    and cl.IsFrauder = 0
    and cl.BankruptType = 0 
    and not exists 
        (
            select 1 from #KongaWithCredit kwc
            where kwc.Passport = cl.Passport collate SQL_Latin1_General_CP1_CI_AS
        )
    and not exists 
        (
            select 1 from #MangoWithCredit mwc
            where mwc.Passport = cl.Passport collate SQL_Latin1_General_CP1_CI_AS
        )
group by 
    cl.clientid
    ,cl.fio
    ,cl.Email
    ,cl.PhoneNumber

/
,upped as 
(
select *
    ,1 as NewTariffType
    ,9 as NewTariffId
    ,'Gold\Gold1' as NewTariffName
from clients c
where c.ProductType = 1
    and c.TariffId in (7, 8)

union
    
select c.*
    ,2 as NewTariffType
    ,ltt.id as NewTariffId
    ,ltt.GroupName + '\' + ltt.name as NewTariffName
from clients c
inner join prd.LongTermTariff ltt on ltt.id = 
                                            case 
                                            when c.TariffId = 7 then 5
                                            when c.TariffId in (8, 9) then 6
                                            when c.TariffId = 10 then 7
                                            when c.TariffId in (11, 12) then 8
                                            end
where c.ProductType = 1
    and not exists 
            (
                select 1 from clients c1
                where c1.clientid = c.clientid
                    and c1.ProductType = 2
                    and c1.TariffId >= ltt.id
                    and c1.islatest = 1
            )

union

select
    c.*
    ,2 as NewTariffType
    ,ltt.id as NewTariffId
    ,ltt.GroupName + '\' + ltt.name as NewTariffName
from clients c
left join prd.LongTermTariff ltt on ltt.Id = (select min(t) from (values (c.TariffId + 4), (8)) as v(t)) 
where c.ProductType = 2
)

,fin as 
(
select *
from upped u
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
    c.clientid
    ,c.Passport
    ,fin.ProductType
    ,fin.NewTariffType
    ,fin.NewTariffId
    ,c.fio
    ,c.PhoneNumber
    ,c.Email
    ,fin.TariffName
    ,fin.NewTariffName
    ,isnull(stt.MaxAmount, ltt.MaxAmount) as MaxAmount
    ,isnull(stt.PercentPerDay, ltt.PercentPerDay) as PercentPerDay
    ,replace(replace((
        select distinct ClientType
        from clients c
        where c.clientid = fin.clientid
        for json auto, without_array_wrapper
    ), '{"ClientType":"', ''), '"}', '') as ClientType
    ,c.substatusName
into #cl
from fin
inner join client.vw_client c on c.clientid = fin.clientid
left join prd.ShortTermTariff stt on stt.Id = fin.NewTariffId
    and fin.NewTariffType = 1
left join prd.LongTermTariff ltt on ltt.Id = fin.NewTariffId
    and fin.NewTariffType = 2
where c.IsFrauder = 0
    and c.IsDead = 0
    and c.IsCourtOrdered = 0
    and c.status < 3
;

create clustered index IX_cl_clientid on #cl(clientid)
;

with OldProductStatus as 
(
    SELECT 1 AS id,N'Активный' AS name
    UNION ALL
    SELECT 2 AS id,N'Погашенный' AS name
    UNION ALL
    SELECT 3 AS id,N'Просроченный' AS name
    UNION ALL
    SELECT 5 AS id,N'Зачисление денег не подтверждено' AS name
    UNION ALL
    SELECT 6 AS id,N'Продленный' AS name
    UNION ALL
    SELECT 7 AS id,N'Погашенный (а)' AS name
    UNION ALL
    SELECT 8 AS id,N'Удаленный' AS name
    UNION ALL
    SELECT 9 AS id,N'Hе было кредитов' AS name
)

select
    cl.*
    ,p.ProductStatusName as LimeProductStatus
    ,k.KongaProductStatus
    ,m.MangoProductStatus
into #cl2
from #cl cl
outer apply
(
    select top 1 ops.Name as KongaProductStatus
    from dbo.br841konga k
    inner join OldProductStatus ops on ops.id = k.status
    where k.Passport = cl.Passport
) k
outer apply
(
    select top 1 ops.Name as MangoProductStatus
    from dbo.br841mango m
    inner join OldProductStatus ops on ops.id = m.status
    where m.Passport = cl.Passport
) m
outer apply
(
    select top 1
        p.productid
        ,p.StartedOn as ProductStartedOn
        ,p.statusName as ProductStatusName
        ,p.status as ProductStatus
        , max(sl.StartedOn) as ProductStatusStart
    from prd.vw_product p
    inner join prd.vw_statusLog sl on sl.ProductId = p.productid
    where cl.clientid = p.clientid
        and p.status > 1
    group by p.StartedOn, p.statusName, p.status, p.productid
    order by p.StartedOn desc
) p
;

select *
into #cl3
from #cl2
where (LimeProductStatus is null or LimeProductStatus = N'Погашен')
    and (KongaProductStatus is null or KongaProductStatus = N'Погашенный')
    and (MangoProductStatus is null or MangoProductStatus = N'Погашенный')
;
/
select count(*) -- update ustt set islatest = 0
from client.UserShortTermTariff ustt
inner join #cl3 c on c.clientid = ustt.clientid
    and c.NewTariffType = 1
    and ustt.islatest = 1
    
select count(*) -- update ultt set islatest = 0
from client.UserLongTermTariff ultt
inner join #cl3 c on c.clientid = ultt.clientid
    and c.NewTariffType = 2
    and ultt.islatest = 1
/*
insert into client.UserShortTermTariff
(
    ClientId, TariffId, CreatedOn, CreatedBy, IsLatest
)
*/
select
    ClientId, NewTariffId, getdate(), cast(0x44 as uniqueidentifier), 1
from #cl3 c
where c.NewTariffType = 1

/*
insert into client.UserLongTermTariff
(
    ClientId, TariffId, CreatedOn, CreatedBy, IsLatest
)
*/
select
    ClientId, NewTariffId, getdate(), cast(0x44 as uniqueidentifier), 1
from #cl3 c
where c.NewTariffType = 2
/
--insert into dbo.CustomListUsers
select
    1058
    ,ClientId
    ,'20180515 14:20'
    ,max(case when NewTariffType = 1 then NewTariffId end)
    ,max(case when NewTariffType = 2 then NewTariffId end)
from #cl3
group by ClientId

select * 
from dbo.CustomListUsers c
where CustomlistID = 1058
/
drop table if exists  #c
;

with prod as 
(
    select
        p.clientId
        ,i.Number
        ,p.StartedOn
        ,p.status
    from prd.vw_product p
    inner join Client.Client c on c.Id = p.clientId
    inner join client."Identity" i on i.ClientId = p.clientId
    where p.status >= 2
        and not exists 
                (
                    select 1 from prd.vw_product p1
                    where p1.clientId =  p.clientId
                        and p1.status >= 2
                        and p1.productid > p.productid
                )
)

select
    clientId
    ,Number as Passport
    ,status
from prod p

create table dbo.br841konga
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

create clustered index IX_br841konga_clientId on dbo.br841konga(clientId)
create clustered index IX_br841mango_clientId on dbo.br841mango(clientId)

/

