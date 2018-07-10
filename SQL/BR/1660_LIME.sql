drop table if exists dbo.br1660DefaultList
;

drop table if exists #th
;

drop table if exists #Clients
;

select 
    th.ClientId
    ,th.ProductType
    ,th.TariffName
    ,cast(dateadd(d, isnull(stt.ActivePeriod, ltt.ActivePeriod), th.CreatedOn) as date) as TariffEndDate
    ,th.IsLatest
into #th
from client.vw_TariffHistory th
left join prd.LongTermTariff ltt on ltt.Id = th.TariffId
    and th.ProductType = 2
left join prd.ShortTermTariff stt on stt.Id = th.TariffId
    and th.ProductType = 1
where (th.IsLatest = 1 
        or datediff(d, dateadd(d, isnull(stt.ActivePeriod, ltt.ActivePeriod), th.CreatedOn), getdate()) <= 45
            and th.IsLatest = 0
            and not exists 
                (
                    select 1 from client.vw_TariffHistory th2
                    left join prd.LongTermTariff ltt2 on ltt2.Id = th2.TariffId
                        and th2.ProductType = 2
                    left join prd.ShortTermTariff stt2 on stt2.Id = th2.TariffId
                        and th2.ProductType = 1
                    where th2.ClientId = th.ClientId
                        and th2.ProductType = th.ProductType
                        and (th2.CreatedOn > th.CreatedOn or th2.IsLatest = 1)
                ))
;

select 
    c.ClientId
    ,c.Passport
into dbo.br1660DefaultList
from client.vw_client c
where exists
    (
        select 1 from #th
        where #th.ClientId = c.CLientId
    )
    and c.IsFrauder = 0
    and c.IsDead = 0
    and c.IsCourtOrdered = 0
    and c.status < 3
    and not exists 
        (
            select 1 from prd.vw_product p
            where p.ClientId = c.clientid
                and p.status not in (5, 1)
        )
;

-- select * from dbo.CustomList 1065

--insert dbo.CustomListUsers
--(
--    CustomlistID, ClientId
--)
--select 1065, ClientId
--from dbo.br1660DefaultList
/

drop table if exists dbo.br1660OtherSystemStatus
;

drop table if exists #OtherServ
;

select *, 'KONGA' as ProductName
into #OtherServ
from "KONGA-DB".LimeZaim_Website.dbo.br1660DefaultList 
;

insert #OtherServ
select *, 'MANGO' as ProductName
from "MANGO-DB".LimeZaim_Website.dbo.br1660DefaultList
;

create clustered index IX_OtherServ on #OtherServ(passport, productname)
;

select
    os.ClientId
    ,os.passport
    ,os.productname
    ,replace(replace(status.ClientStatus, '{"substatusName":', ''), '}', '') as ClientStatus
    ,replace(replace(p.ProductStatus, '{"StatusName":', ''), '}', '') as ProductStatus
into dbo.br1660OtherSystemStatus
from #OtherServ os
outer apply
(
    select distinct 
        c.substatusName
    from client.vw_client c 
    where c.Passport = os.Passport
    order by c.substatusName
    for json auto, without_array_wrapper
) status(ClientStatus)
outer apply
(
    select
        p.StatusName
    from prd.vw_product p
    inner join client.vw_client c on p.ClientId = c.clientid
    where c.Passport = os.Passport
        and p.Status > 2
        and not exists 
            (
                select 1 from prd.vw_product p2
                where p2.ClientId = p.ClientId
                    and p2.Status > 2
                    and p2.StartedOn > p.StartedOn
            )
    for json auto, without_array_wrapper
) p(ProductStatus)

/
select
    c.ClientId
    ,c.fio
    ,c.Email
    ,c.PhoneNumber
    ,c.DateRegistered
    ,p.Amount as LastCreditAmount
    ,p.DatePaid as LastCreditDatePaid
    ,st.TariffName as STTariffName
    ,st.TariffEndDate as STTariffEndDate
    ,st.IsLatest as STIsLatest
    ,lt.TariffName as LTTariffName
    ,lt.TariffEndDate as LTTariffEndDate
    ,lt.IsLatest as LTIsLatest
    ,k.ClientStatus as KongaClientStatus
    ,k.ProductStatus as KongaProductStatus
    ,m.ClientStatus as MangoClientStatus
    ,m.ProductStatus as MangoProductStatus
    ,s.score
from dbo.br1660DefaultList ul
inner join "KONGA-DB".LimeZaim_Website.dbo.br1660OtherSystemStatus k on k.clientid = ul.clientid
    and k.ProductName = 'Lime'
inner join "MANGO-DB".LimeZaim_Website.dbo.br1660OtherSystemStatus m on m.clientid = ul.clientid
    and m.ProductName = 'Lime'
inner join client.vw_Client c on c.clientid = ul.ClientId
left join #th st on st.ClientId = ul.ClientId
    and st.ProductType = 1
left join #th lt on lt.ClientId = ul.ClientId
    and lt.ProductType = 2
left join dbo.br1660Score s on s.userid = ul.ClientId
outer apply
(
    select top 1
        p.Amount
        ,p.DatePaid
    from prd.vw_product p
    where p.ClientId = ul.ClientId
    order by p.DatePaid desc
) p
where (k.ProductStatus not like N'%"Просроченный"%' and k.ProductStatus not like N'%"Активный"%' or k.ProductStatus is null)
    and (m.ProductStatus not like N'%"Просроченный"%' and m.ProductStatus not like N'%"Активный"%' or m.ProductStatus is null) 
