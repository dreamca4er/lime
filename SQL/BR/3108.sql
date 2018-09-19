drop table if exists #un
;

drop table if exists #a
;

with a as 
(
    select
        b.*
        ,stt.id as NewSTTariffId
        ,ltt.id as NewLTTariffId
        ,stt.MaxAmount as NewSTMaxAmount
        ,ltt.MaxAmount as NewLTMaxAmount
        ,ustt.TariffId as OldSTTariffId
        ,ultt.TariffId as OldLTTariffId
        ,ostt.MaxAmount as OldSTMaxAmount
        ,oltt.MaxAmount as OldLTMaxAmount
    from dbo.br3108 b
    inner join client.Client c on c.id = b.clientid
    left join prd.ShortTermTariff stt on concat(stt.GroupName, '\', stt.Name) = b.st
    left join prd.LongTermTariff ltt on concat(ltt.GroupName, '\', ltt.Name) = b.lt
    left join client.vw_TariffHistory ustt on ustt.ClientId = b.clientid
        and ustt.IsLatest = 1
        and ustt.ProductType = 1
    left join client.vw_TariffHistory ultt on ultt.ClientId = b.clientid
        and ultt.IsLatest = 1
        and ultt.ProductType = 2
    left join prd.ShortTermTariff ostt on ostt.id = ustt.TariffId
    left join prd.LongTermTariff oltt on oltt.id = ultt.TariffId
    where (b.st != '' or b.lt != '')
        and (b.st = '' or stt.id > ustt.TariffId or ustt.id is null)
        and (b.lt = '' or ltt.id > ultt.TariffId or ultt.id is null)
        and not exists 
            (
                select 1 from prd.vw_product p
                where p.ClientId = b.clientid
                    and p.Status in (2, 3, 4, 7)
            )
        and c.IsFrauder = 0
        and c.IsDead = 0
        and c.IsCourtOrdered = 0
        and c.Status = 2
)

select *
into #a
from a
;

with un as 
(
    select
        clientid
        ,NewSTTariffId as NewTariffId 
        ,1 as ProductType
    from #a a
    where (NewSTTariffId > OldSTTariffId or OldSTTariffId is null)
        and NewSTTariffId is not null
    
    union
    
    select
        clientid
        ,NewLTTariffId
        ,2 as ProductType
    from #a a
    where (NewLTTariffId > OldLTTariffId or OldLTTariffId is null)
        and NewLTTariffId is not null
)

select *
into #un
from un
;

/ 
select t.* -- update t set islatest = 0
from #un u
inner join client.UserShortTermTariff t on t.ClientId = u.clientid
    and t.IsLatest = 1
where u.ProductType = 1
;
--
--insert client.UserShortTermTariff
--(
--    ClientId, TariffId, CreatedOn, CreatedBy, IsLatest
--)
select
    ClientId
    ,NewTariffId as TariffId
    ,getdate() as CreatedOn
    ,cast(0x0 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
from #un u
where u.ProductType = 1

select t.* -- update t set islatest = 0
from #un u
inner join client.UserLongTermTariff t on t.ClientId = u.clientid
    and t.IsLatest = 1
where u.ProductType = 2
;

--insert client.UserLongTermTariff
--(
--    ClientId, TariffId, CreatedOn, CreatedBy, IsLatest
--)
select
    ClientId
    ,NewTariffId as TariffId
    ,getdate() as CreatedOn
    ,cast(0x0 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
from #un u
where u.ProductType = 2
;

select
    a.clientid
    ,c.LastName
    ,c.FirstName
    ,c.FatherName
    ,c.Email
    ,c.PhoneNumber
    ,sth.TariffName as STTariffName
    ,lth.TariffName as LTTariffName
    ,(select max(ts) from (values (NewSTMaxAmount), (NewLTMaxAmount), (OldSTMaxAmount), (OldLTMaxAmount)) ct(ts)) as ClientMaxSum
from #a a
inner join client.vw_Client c on c.clientid = a.clientid
left join client.vw_TariffHistory sth on sth.ClientId = c.clientid
    and sth.IsLatest = 1
    and sth.ProductType = 1
left join client.vw_TariffHistory lth on lth.ClientId = c.clientid
    and lth.IsLatest = 1
    and lth.ProductType = 2