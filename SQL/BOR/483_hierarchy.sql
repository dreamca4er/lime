--aoguid,name,parentguid,aolevel,centstatus,regioncode,postalcode

CREATE TABLE [dict].[hierarchy]  ( 
    [id]            int IDENTITY(1,1) NOT NULL,
    [aoguid]        nvarchar(255) NULL,
    [name]          nvarchar(255) NULL,
    [parentguid]    nvarchar(255) NULL,
    [centstatus]    int NULL,
    [regioncode]    nvarchar(255) NULL,
    [postalcode]    nvarchar(255) NULL,
    [aolevel]       int NULL
)
GO
;

with h (aoguid, name, parentguid, centstatus, regioncode, postalcode, aolevel) as 
(
    select
        a.aoguid
        ,cast(a.FORMALNAME + ' ' + a.SHORTNAME as nvarchar(255)) name
        ,cast(null as nvarchar(255)) as parentguid
        ,cast(a.centstatus as smallint) as centstatus
        ,cast(a.regioncode as int) as regioncode
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
            when cast(a.CENTSTATUS as smallint) > h.CENTSTATUS
            then cast(a.CENTSTATUS as smallint)
            else h.CENTSTATUS
        end as centstatus
        ,cast(a.regioncode as int) as regioncode
        ,a.postalcode
        ,a.aolevel
    from dict.addrobj a
    inner join h on h.aoguid = a.PARENTGUID
    where a.ACTSTATUS = 1
)

insert into dict.hierarchy (aoguid,name,parentguid,centstatus,regioncode,postalcode,aolevel)
select aoguid,name,parentguid,centstatus,regioncode,postalcode,aolevel
from h
;

create index hierarchy_aoguid_idx on dict.hierarchy(aoguid)
;

create index hierarchy_parentguid_idx on dict.hierarchy(parentguid)
;

alter table dict.hierarchy add constraint pk_hierarchy_id primary key (id)
;

create fulltext index on dict.hierarchy (name) key index pk_hierarchy_id
with (change_tracking auto)
;

alter table dict.hierarchy
add constraint uq_hierarchy_aoguid unique(aoguid)
;
