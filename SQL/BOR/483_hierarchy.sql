--aoguid,name,parentguid,aolevel,centstatus,regioncode,postalcode

with h (aoguid, name, parentguid, centstatus, regioncode, postalcode, aolevel) as 
(
    select
        a.aoguid
        ,cast(a.FORMALNAME + ' ' + a.SHORTNAME as nvarchar(255)) name
        ,cast(null as nvarchar(255)) as parentguid
        ,a.centstatus
        ,a.regioncode
        ,a.postalcode
        ,a.aolevel
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
            when a.CENTSTATUS > h.CENTSTATUS
            then a.CENTSTATUS
            else h.CENTSTATUS
        end as centstatus
        ,a.regioncode
        ,a.postalcode
        ,a.aolevel
    from dict.addrobj a
    inner join h on h.aoguid = a.PARENTGUID
    where a.ACTSTATUS = 1
)


select
    row_number() over (order by aoguid) as id
    ,*
into dict.hierarchy
from h
;

create index hierarchy_aoguid_idx on dict.hierarchy(aoguid)
;

create index hierarchy_parentguid_idx on dict.hierarchy(parentguid)
;

alter table dict.hierarchy alter column id integer not null
;

alter table dict.hierarchy add constraint pk_hierarchy_id primary key (id)
;

create fulltext index on dict.hierarchy (name) key index pk_hierarchy_id
with (change_tracking auto)
;