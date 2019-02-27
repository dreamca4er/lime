select
    case when rcnt = 1 then 1 else 0 end as RAddrUniqCnt
    , case when fcnt = 1 then 1 else 0 end as FAddrUniqCnt
    , count(*) as cnt
from 
(
    select 
        ClientId
        , count(distinct RegAddressStr) as rcnt
        , count(distinct FactAddressStr) as fcnt
    from client.ClientCardLog
    group by ClientId
) c
group by
    case when rcnt = 1 then 1 else 0 end
    , case when fcnt = 1 then 1 else 0 end 
/
select ClientId
into dbo.br6778_2
from 
(
    select 
        ClientId
        , count(distinct RegAddressStr) as rcnt
        , count(distinct FactAddressStr) as fcnt
    from client.ClientCardLog
    where RegAddressStr is not null
        and FactAddressStr is not null
    group by ClientId
) c
where not (rcnt = 1 
    and fcnt = 1)
/

create clustered index IX_dbo_br6778_ClientId on dbo.br6778(ClientId)
;

alter table dbo.br6778 add IsDone bit
/

select
    IsDone
    , count(*)
from dbo.br6778
group by IsDone
;

update top (40000) l
set IsDone = 0
from dbo.br6778 l
where IsDone is null
;

--select
--    l.ClientId
--    , isnull(ar.AddressStr + isnull(N', кв. ' + nullif(ar.Apartment, '0'), ''), '') as RegAddress
--    , isnull(af.AddressStr + isnull(N', кв. ' + nullif(af.Apartment, '0'), ''), '') as FactAddress
--    , ccl.RegAddressStr
--    , ccl.FactAddressStr
update ccl
set 
    ccl.RegAddressStr = isnull(ar.AddressStr + isnull(N', кв. ' + nullif(ar.Apartment, '0'), ''), '')
    , ccl.FactAddressStr = isnull(af.AddressStr + isnull(N', кв. ' + nullif(af.Apartment, '0'), ''), '')
from dbo.br6778 l
inner join client.Address ar on ar.ClientId = l.ClientId
    and ar.AddressType = 1
left join client.Address af on af.ClientId = l.ClientId
    and af.AddressType = 2
inner join client.ClientCardLog ccl on ccl.ClientId = l.ClientId
where l.IsDone = 0
;

update l
set IsDone = 1
from dbo.br6778 l
where IsDone = 0 
;

select
    IsDone
    , count(*)
from dbo.br6778
group by IsDone
;


/

select top 100 *
from dbo.br6778_2

/

select
    l.ProjectClientId
    , l.Date
    , l.Type
    , cast(p8.Address as nvarchar(200)) as Address
into dbo.br6778_parsed
from dbo.br6778_mango_ready l
outer apply
(
    select replace(l.Address, 'RU, ', '') as Address
) p
outer apply
(
    select iif(
                p.Address like replicate('[0-9]', 6) + ', ' + replicate('[0-9]', 2) + ', %'
                , stuff(p.Address, 1, 12, '')
                , p.Address) as Address
) p2
outer apply
(
    select iif(
                p2.Address like replicate('[0-9]', 6) + ', %'
                , stuff(p2.Address, 1, 8, '')
                , p2.Address) as Address
) p3
outer apply
(
    select iif(
                p3.Address like '[0-9][0-9], %'
                , stuff(p3.Address, 1, 4, '')
                , p3.Address) as Address
) p4
outer apply
(
    select iif(
                p4.Address like replicate('[0-9]', 6) + ', ' + replicate('[0-9]', 2) + ', %'
                , stuff(p4.Address, 1, 12, '')
                , p4.Address) as Address
) p5
outer apply
(
    select iif(
                p5.Address like replicate('[0-9]', 5) + ', ' + replicate('[0-9]', 2) + ', %'
                , stuff(p5.Address, 1, 11, '')
                , p5.Address) as Address
) p6
outer apply
(
    select ltrim(rtrim(iif(
                p6.Address like N'РОССИЙСКАЯ ФЕДЕРАЦИЯ,%'
                , stuff(p6.Address, 1, 21, '')
                , p6.Address))) as Address
) p7
outer apply
(
    select ltrim(rtrim(iif(
                p7.Address like replicate('[0-9]', 6) + ',%'
                , stuff(p7.Address, 1, 7, '')
                , p7.Address))) as Address
) p8
/

update ccl
set 
    ccl.RegAddressStr =
    case
        when ccl.RegAddressStr != '' and isnull(r.Address, car.AddressStr) is not null
        then isnull(r.Address, car.AddressStr + isnull(N', кв. ' + nullif(car.Apartment, '0'), ''))
        else ccl.RegAddressStr
    end
    ,  ccl.FactAddressStr = 
    case
        when ccl.FactAddressStr != '' and isnull(f.Address, caf.AddressStr) is not null
        then isnull(f.Address, caf.AddressStr + isnull(N', кв. ' + nullif(caf.Apartment, '0'), ''))
        else ccl.FactAddressStr
    end
from dbo.br6778_2 l
inner join client.ClientCardLog ccl on ccl.ClientId = l.ClientId
left join client.Address car on car.ClientId = l.ClientId
    and car.AddressType = 1
left join client.Address caf on caf.ClientId = l.ClientId
    and caf.AddressType = 2
outer apply
(
    select top 1 
        p.Address
    from dbo.br6778_parsed p
    where p.ProjectClientId = l.ClientId
        and p.Type = 1
        and p.Date <= cast(ccl.CreatedOn as date)
        and len(p.Address) >= 30
    order by p.Date desc
) r
outer apply
(
    select top 1 
        p.Address
    from dbo.br6778_parsed p
    where p.ProjectClientId = l.ClientId
        and p.Type = 2
        and p.Date <= cast(ccl.CreatedOn as date)
        and len(p.Address) >= 30
    order by p.Date desc
) f
