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
into dict.hierarchy4
from h
;

create index hierarchy_aoguid_idx on dict.hierarchy4(aoguid)
;

create index hierarchy_parentguid_idx on dict.hierarchy4(parentguid)
;

alter table dict.hierarchy4 alter column id integer not null
;

alter table dict.hierarchy4 add constraint pk_hierarchy_id primary key (id)
;

create fulltext index on dict.hierarchy4 (name) key index pk_hierarchy_id
with (change_tracking auto)
;

select top 100 *
from dict.houseactive2
where postalcode is null
/
select 
    ha.HOUSEGUID
    ,ha.AOGUID
    ,coalesce(ha.POSTALCODE, h.POSTALCODE) as POSTALCODE
    ,h.name + ', ' + ha.HOUSENUM as houseaddr
    ,h.regioncode
    ,h.centstatus
into dict.houseactive2
from dict.houseactive ha
inner join dict.hierarchy2 h on h.aoguid = ha.AOGUID
/
alter table dict.houseactive2
alter column HOUSEGUID uniqueidentifier not null
/
ALTER TABLE dict.houseactive2 ADD  CONSTRAINT [PK_houseactive2_houseguid] PRIMARY KEY 
([HOUSEGUID] ASC)

select top 100 *
from dict.houseactive2

create FULLTEXT INDEX  ON dict.houseactive2 (houseaddr) KEY INDEX PK_houseactive2_houseguid
WITH (CHANGE_TRACKING AUTO)
/

create index houseactive2_aoguid_idx on dict.houseactive2(aoguid)