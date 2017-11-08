--aoguid,name,parentguid,aolevel,centstatus,regioncode,postalcode
select *
from dict.hierarchy
where contains(name, N'"новосибирский р-н"')

--2553
/
/*
CTE deltaAddrObj заменить на addrobj_delta
*/

drop table if exists dict.hierarchyUpdate
;

with deltaAddrObj as 
(       
    select distinct aoguid
    from (select '16932400-c8e3-4a17-8c57-d96f30a183ce' as aoguid) a
)

,h (aoguid, name, parentguid, centstatus, regioncode, postalcode, aolevel, isNeeded) as 
(
    select
        a.aoguid
        ,cast(a.FORMALNAME + ' ' + a.SHORTNAME as nvarchar(255)) name
        ,cast(null as nvarchar(255)) as parentguid
        ,cast(a.centstatus as smallint) as centstatus
        ,cast(a.regioncode as int) as regioncode
        ,a.postalcode
        ,a.aolevel
        ,case
            when a.aoguid in 
                            (
                                select aoguid from deltaAddrObj
                            )
            then 1 
            else 0
        end as isNeeded
    from dict.addrobj a
    where a.ACTSTATUS = 1
        and a.AOLEVEL = 1
--        and a.aoguid = '8d3f1d35-f0f4-41b5-b5b7-e7cadf3e7bd7'

    union all

    select
        a.aoguid
        ,cast(name + ', ' + a.FORMALNAME + ' ' + a.SHORTNAME as nvarchar(255))
        ,a.parentguid
        ,case 
            when cast(a.CENTSTATUS as smallint) > h.CENTSTATUS
            then cast(a.CENTSTATUS as smallint)
            else h.CENTSTATUS
        end as centstatus
        ,cast(a.regioncode as int) as regioncode
        ,a.postalcode
        ,a.aolevel
        ,case
            when a.aoguid in 
                            (
                                select aoguid from deltaAddrObj
                            )
              or h.isNeeded = 1            
            then 1 
            else 0
        end as isNeeded
    from dict.addrobj a
    inner join h on h.aoguid = a.PARENTGUID
    where a.ACTSTATUS = 1
)


select
    row_number() over (order by aoguid) as id
    ,*
into dict.hierarchyUpdate
from h
where isNeeded = 1
;

delete from dict.hierarchy
where aoguid in
                (
                    select aoguid
                    from  #hierarchyUpdate
                )
;

insert into dict.hierarchy(aoguid, name, parentguid, centstatus, regioncode, postalcode, aolevel)
select aoguid, name, parentguid, centstatus, regioncode, postalcode, aolevel
from dict.hierarchyUpdate

