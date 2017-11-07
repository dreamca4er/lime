with h (aoguid, parentguid, CENTSTATUS, regioncode, POSTALCODE) as 
(
    select
        a.aoguid
        ,cast(null as nvarchar(255)) as parentguid
        ,a.CENTSTATUS
        ,a.REGIONCODE
        ,a.POSTALCODE
    from dict.addrobj a
    where a.ACTSTATUS = 1
        and a.AOLEVEL = 1
--        and a.aoguid = '8d3f1d35-f0f4-41b5-b5b7-e7cadf3e7bd7'

    union all

    select
        a.aoguid
        ,a.parentguid
        ,case 
            when a.CENTSTATUS > h.CENTSTATUS
            then a.CENTSTATUS
            else h.CENTSTATUS
        end as CENTSTATUS
        ,a.REGIONCODE
        ,a.POSTALCODE
    from dict.addrobj a
    inner join h on h.aoguid = a.PARENTGUID
    where a.ACTSTATUS = 1
)

select *
into dict.hierarchy3
from h

create index hierarchy3_aoguid_idx on dict.hierarchy3(aoguid)
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