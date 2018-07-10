drop table if exists dbo.br993Lime
;
/*
a.	Есть тариф и нет активного кредита
b.	Тариф истек в последние 90 дней и нет активного кредита
c.	Последний заем погашен в промежутке от 10 до 120 дней назад от текущей даты и нет активного кредита
*/
with ClientList1 as
(
    select 
        c.clientid
        ,c.Passport
    from client.vw_client c
    where c.Substatus = 203
        and not exists
            (
                select 1 from prd.vw_product p
                where p.clientId = c.clientid
                    and p.status in (3, 4, 7)
            )
        and exists
            (
                select 1 from client.vw_TariffHistory th
                where th.ClientId = c.clientid
                    and th.IsLatest = 1
            )
        and c.IsDead = 0
        and c.IsFrauder = 0
        and c.IsCourtOrdered = 0
        and c.BankruptType = 0
        and c.DebtorProhibitInteractionType = 0
        and c.status < 3

    union

    select 
        c.clientid
        ,c.Passport
    from client.vw_client c
    where exists
            (
                select 1 from client.vw_TariffHistory th
                left join prd.ShortTermTariff stt on stt.Id = th.TariffId
                    and th.ProductType = 1
                left join prd.LongTermTariff ltt on ltt.Id = th.TariffId
                    and th.ProductType = 2
                where dateadd(d, isnull(stt.ActivePeriod, ltt.ActivePeriod), th.CreatedOn) >= dateadd(d, -90, getdate())
                    and th.ClientId = c.clientid
                    and th.islatest = 0
            )
        and not exists
            (
                select 1 from client.vw_TariffHistory th
                where th.ClientId = c.clientid
                    and th.islatest = 1
            )
        and not exists
            (
                select 1 from prd.vw_product p
                where p.clientId = c.clientid
                    and p.status in (3, 4, 7)
            )
        and c.IsDead = 0
        and c.IsFrauder = 0
        and c.IsCourtOrdered = 0
        and c.BankruptType = 0
        and c.DebtorProhibitInteractionType = 0
        and c.status < 3

    union

    select 
        c.clientid
        ,c.Passport
    from client.vw_client c
    where exists
            (
                select 1 from prd.vw_product p
                where p.clientId = c.clientid
                    and p.status = 5
                    and datediff(d, p.datePaid, getdate()) + 1 between 10 and 120
            )
        and not exists
            (
                select 1 from prd.vw_product p
                where p.clientId = c.clientid
                    and p.status in (3, 4, 7)
            )
        and c.IsDead = 0
        and c.IsFrauder = 0
        and c.IsCourtOrdered = 0
        and c.BankruptType = 0
        and c.DebtorProhibitInteractionType = 0
        and c.status < 3
)

/*
Необходим список всех клиентов, которые зарегались, но по которым не была получена КИ. То есть те клиенты, которых мы никогда не блокировали и которые никогда не брали деньги
*/
,ClientList2 as 
(
    select
        c.clientid
        ,c.Passport
    from client.vw_client c
    where not exists
            (
                select 1 from prd.product p
                where p.clientId = c.clientid
            )
        and not exists
            (
                select 1 from client.vw_TariffHistory th
                where th.ClientId = c.clientid
            )
        and not exists 
            (
                select 1 from cr.EquifaxRequest req
                where req.ClientId = c.clientid
            )
        and not exists 
            (
                select 1 from client.UserStatusHistory ush
                where ush.ClientId = c.clientid
                    and ush.Substatus not in (101, 102, 201, 202)
            )
        and c.IsDead = 0
        and c.IsFrauder = 0
        and c.IsCourtOrdered = 0
        and c.BankruptType = 0
        and c.DebtorProhibitInteractionType = 0
        and c.status < 3
)

/*
Необходим список всех клиентов, которые имеют активный или реструктурированный заем в Компании Лайм. 
*/
,ClientList3 as 
(
    select 
        c.clientid
        ,c.Passport
    from client.vw_client c
    where exists
            (
                select 1 from prd.vw_product p
                where p.clientId = c.clientid
                    and p.status in (3, 7)
            )
        and c.IsDead = 0
        and c.IsFrauder = 0
        and c.IsCourtOrdered = 0
        and c.BankruptType = 0
        and c.DebtorProhibitInteractionType = 0
        and c.status < 3
)

/*
Необходим список всех клиентов, которые имеют просроченный заем в Компании Лайм, при этом срок просрочки не более 90 дней
*/
,ClientList4 as 
(
    select 
        c.clientid
        ,c.Passport
    from client.vw_client c
    where exists
        (
            select 1
            from prd.vw_product p
            cross apply
            (
                select top 1 sl.StartedOn as OverdueStart
                from prd.vw_statusLog sl
                where sl.ProductId = p.productid
                order by sl.StartedOn desc
            ) sl
            where p.clientId = c.clientid
                and p.status = 4
                and datediff(d, sl.OverdueStart, getdate()) + 1 <= 90
        ) 
        and c.IsDead = 0
        and c.IsFrauder = 0
        and c.IsCourtOrdered = 0
        and c.BankruptType = 0
        and c.DebtorProhibitInteractionType = 0
        and c.status < 3
)

/*
Нужен тариф повторно. 
Выбираем всех клиентов у кого выполняются одновременно следующие условия (a И b):
a.	Тариф истек более чем 90 дней назад и нет активного кредита
b.	Последний заем погашен в промежутке более 120 дней назад от текущей даты и нет активного кредита
*/
,ClientList5 as 
(
    select 
        c.clientid
        ,c.Passport
    from client.vw_client c
    where exists
            (
                select 1 from client.vw_TariffHistory th
                left join prd.ShortTermTariff stt on stt.Id = th.TariffId
                    and th.ProductType = 1
                left join prd.LongTermTariff ltt on ltt.Id = th.TariffId
                    and th.ProductType = 2
                where dateadd(d, isnull(stt.ActivePeriod, ltt.ActivePeriod), th.CreatedOn) >= dateadd(d, -90, getdate())
                    and th.ClientId = c.clientid
                    and th.islatest = 0
            )
        and not exists
            (
                select 1 from client.vw_TariffHistory th
                where th.ClientId = c.clientid
                    and th.islatest = 1
            )
        and not exists
            (
                select 1 from prd.vw_product p
                where p.clientId = c.clientid
                    and p.status not in (1, 5)
            )
        and exists
            (
                select 1 from prd.vw_product p
                where p.clientId = c.clientid
                    and p.status = 5
                    and datediff(d, p.datePaid, getdate()) > 120
            )
        and not exists
            (
                select 1 from prd.vw_product p
                where p.clientId = c.clientid
                    and p.status = 5
                    and datediff(d, p.datePaid, getdate()) <= 120
            )
        and c.IsDead = 0
        and c.IsFrauder = 0
        and c.IsCourtOrdered = 0
        and c.BankruptType = 0
        and c.DebtorProhibitInteractionType = 0
        and c.status < 3
)

select
    clientid
    ,Passport
into dbo.br993Lime
from ClientList5
;

create clustered index IX_dbo_br993Lime_clientid on dbo.br993Lime(clientid)
;

/

drop table if exists #clFullList
;

select *
into #clFullList
from
(
    select *
    from dbo.br993Lime

    union

    select
        null
        ,passport collate SQL_Latin1_General_CP1_CI_AS as passport
    from "KONGA-DB".LimeZaim_Website.dbo.br993Konga k
    where isnull(passport, replicate('0', 10)) not in (replicate('0', 10), '')
        and not exists
            (
                select 1
                from dbo.br993Lime cl
                where cl.passport = k.passport collate SQL_Latin1_General_CP1_CI_AS
            )

    union

    select
        null
        ,passport collate SQL_Latin1_General_CP1_CI_AS as passport
    from "MANGO-DB".LimeZaim_Website.dbo.br993Mango m
    where isnull(passport, replicate('0', 10)) not in (replicate('0', 10), '')
        and not exists
            (
                select 1
                from dbo.br993Lime cl
                where cl.passport = m.passport collate SQL_Latin1_General_CP1_CI_AS
            )
) c

create index IX_passport_clientid_clFullList on #clFullList(passport, clientid)

/


drop table if exists #LimeList
;

select *
into #LimeList
from
(
select
    c.clientid
    ,case when cl.clientid is not null then 1 end as LimeNeeded
    ,c.fio
    ,c.Email
    ,c.PhoneNumber
    ,c.Passport
    ,c.substatusName
from client.vw_client c
inner join #clFullList cl on cl.clientid = c.clientid

union

select
    c.clientid
    ,case when cl.clientid is not null then 1 end as LimeNeeded
    ,c.fio
    ,c.Email
    ,c.PhoneNumber
    ,c.Passport
    ,c.substatusName
from client.vw_client c
inner join #clFullList cl on cl.clientid is null
    and c.passport = cl.passport
) a

create index IX_LimeList_clientid on #LimeList(clientid)
;

drop table if exists dbo.br993
;

select 
    c.clientid
    ,c.LimeNeeded
    ,c.fio
    ,c.Email
    ,c.PhoneNumber
    ,c.Passport
    ,stt.TariffName as STTariffName
    ,stt.islatest as STIsActive
    ,ltt.TariffName as LTTariffName
    ,ltt.islatest as LTIsActive
    ,c.substatusName as LimeUserStatus
    ,cs.statusName as LimeCreditStatus
    ,cs.OverdueDays as LimeOverdueDays
into dbo.br993
from #LimeList c
outer apply
(
    select top 1
        th.TariffName
        ,th.IsLatest
    from client.vw_TariffHistory th
    where th.ClientId = c.clientid
        and th.ProductType = 1
    order by case when th.IsLatest = 1 then 1 else 2 end, th.CreatedOn desc
) stt
outer apply
(
    select top 1
        th.TariffName
        ,th.IsLatest
    from client.vw_TariffHistory th
    where th.ClientId = c.clientid
        and th.ProductType = 2
    order by case when th.IsLatest = 1 then 1 else 2 end, th.CreatedOn desc
) ltt
outer apply
(
    select top 1
        p.statusName
        ,case when sl.status = 4 then datediff(d, sl.StartedOn, getdate()) + 1 end as OverdueDays
    from prd.vw_product p
    outer apply
    (
        select top 1
            sl.Status
            ,sl.StartedOn
        from prd.vw_statusLog sl
        where sl.ProductId = p.productid
        order by sl.StartedOn desc
    ) sl
    where p.clientId = c.clientid
        and p.status != 1
    order by
        case when p.status != 5 then 1 else 2 end
        ,p.datePaid desc
) cs

create index IX_br993_passport on dbo.br993(Passport) where LimeNeeded = 1
create clustered index IX_br993_passport_client on dbo.br993(Passport, clientid desc)

/

drop table if exists #k
;

select *
into #k
from "KONGA-DB".LimeZaim_Website.dbo.br993 k

drop table if exists #m
;

select *
into #m
from "MANGO-DB".LimeZaim_Website.dbo.br993 m
;

create index IX_k_passport on #k(passport)
;

create index IX_m_passport on #m(passport)
;


drop table if exists dbo.br993Fin
;

select
    b.*
    ,k.KongaUserStatus
    ,k.KongaCreditStatus
    ,k.KongaOverdueDays
    ,m.MangoUserStatus
    ,m.MangoCreditStatus
    ,m.MangoOverdueDays
into dbo.br993Fin
from dbo.br993 b
outer apply
(
    select top 1 *
    from #m m 
    where m.passport = b.passport 
) m
outer apply
(
    select top 1 *
    from #k k 
    where k.passport = b.passport 
) k
where b.LimeNeeded = 1
/
/*
select * --select top 10 *
from dbo.br993Fin
*/



select
    f.*
    ,s.score
from dbo.br993Fin f
left join dbo.br993Score s on f.clientid = s.clientid