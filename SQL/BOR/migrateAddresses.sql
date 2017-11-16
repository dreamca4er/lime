drop table if exists #locs
;

with locs_pre as 
(
    select distinct
        llc.Title as cityTitle
        ,lls.title as streetTitle
        ,ual.CityId
        ,ual.StreetId
        ,case 
            when charindex('_', llc.KladrCode) > 0
            then substring(llc.KladrCode, 0, charindex('_', llc.KladrCode)) 
            else llc.KladrCode
        end as KladrCode
        ,'lime' as product
    from prod.UserAddressesLime ual
    inner join prod.LocationsLime llc on llc.Id = ual.CityId
    left join prod.LocationsLime lls on lls.id = ual.StreetId

union

    select distinct
        llc.Title as cityTitle
        ,lls.title as streetTitle
        ,ual.CityId
        ,ual.StreetId
        ,case 
            when charindex('_', llc.KladrCode) > 0
            then substring(llc.KladrCode, 0, charindex('_', llc.KladrCode)) 
            else llc.KladrCode
        end as KladrCode
        ,'konga' as product
    from prod.UserAddressesKonga ual
    inner join prod.LocationsKonga llc on llc.Id = ual.CityId
    left join prod.LocationsKonga lls on lls.id = ual.StreetId

union

    select distinct
        llc.Title as cityTitle
        ,lls.title as streetTitle
        ,ual.CityId
        ,ual.StreetId
        ,case 
            when charindex('_', llc.KladrCode) > 0
            then substring(llc.KladrCode, 0, charindex('_', llc.KladrCode)) 
            else llc.KladrCode
        end as KladrCode
        ,'mango' as product
    from prod.UserAddressesMango ual
    inner join prod.LocationsMango llc on llc.Id = ual.CityId
    left join prod.LocationsMango lls on lls.id = ual.StreetId
)

,locs as 
(
    select distinct
        lp.cityTitle
        ,lp.streetTitle
        ,lp.CityId
        ,lp.StreetId
        ,len(lp.KladrCode) as codeLen
        ,case 
            when len(lp.KladrCode) < 5 then left(lp.KladrCode, 2)
            when len(lp.KladrCode) < 8 then left(lp.KladrCode, 5)
            when len(lp.KladrCode) < 11 then left(lp.KladrCode, 8)
            when len(lp.KladrCode) < 15 then left(lp.KladrCode, 11)
            else left(lp.KladrCode, 15)
        end as trimmedCode
        ,lp.KladrCode as cityCode
        ,product
    from locs_pre lp
)

select *
into #locs
from locs
;

drop table if exists #locsCity
;

select distinct 
    trimmedCode
    ,cityCode
into #locsCity
from #locs
;

drop table if exists #citiesFias
;

select
    l.*
    ,coalesce(aoCity.FORMALNAME + ' ' + aoCity.SHORTNAME, aoCityOld.aoCityNameold) as aoCityName
    ,coalesce(aoCity.aoguid, aoCityOld.aoguid) as aoguid
into #citiesFias
from #locsCity l
left join dict.addrobj aoCity on aoCity.PLAINCODE = l.trimmedCode
    and aoCity.ACTSTATUS = 1
outer apply
(
    select top 1
        aoCityOld.aoguid
        ,aoCityOld.FORMALNAME + ' ' + aoCityOld.SHORTNAME as aoCityNameold
    from dict.addrobj aoCityOld
    where aoCityOld.PLAINCODE = l.trimmedCode
        and aoCityOld.ACTSTATUS = 0
        and aoCity.aoguid is null
    order by aoCityOld.CURRSTATUS, enddate desc
) aoCityOld
;

drop table if exists #locs2
;

select
    l.*
    ,cf.aoCityName
    ,cf.aoguid
into #locs2
from #citiesFias cf
left join #locs l on cf.trimmedCode = l.trimmedCode
;

drop table if exists #locs3
;

select
    streetGuid
    ,name as address
    ,regioncode
    ,postalcode
    ,l.product
    ,l.CityId
    ,l.StreetId
    ,l.cityTitle
    ,l.streetTitle
    ,trimmedCode
    ,cityCode
into #locs3
from #locs2 l
outer apply
(
    select top 1
        ao.AOGUID as streetGuid
        ,ao.FORMALNAME as aoStreetname
        ,ao.SHORTNAME as aoStreetSN
    from dict.addrobj ao
    where ao.PARENTGUID = l.aoguid
        and ao.FORMALNAME = l.streetTitle
    order by 
        ACTSTATUS desc
        ,CURRSTATUS
        ,ENDDATE desc
) ao
left join dict.hierarchy h on h.aoguid = ao.streetGuid
;

drop table if exists mg.parsedAddresses
;

create table mg.parsedAddresses (
    id int not null identity(1, 1)
    ,aoguid nvarchar(36)
    ,address nvarchar(255)
    ,regioncode nvarchar(4)
    ,postalcode nvarchar(6)
    ,product nvarchar(10)
    ,cityid int
    ,streetid int
    ,cityTitle nvarchar(50)
    ,streetTitle nvarchar(50)
    ,trimmedCode nvarchar(25)
    ,cityCode nvarchar(25)
)
;

insert into mg.parsedAddresses(aoguid,address,regioncode,postalcode,product,cityid,streetid,cityTitle,streetTitle,trimmedCode,cityCode)
select *
from #locs3


select top 1 *
from 