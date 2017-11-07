drop table if exists dict.houseactive2
;

with m as 
(
select
    HOUSEGUID
    ,max(ENDDATE) as ENDDATE
from dict.house
group by HOUSEGUID
)

select
    h.HOUSEGUID
    ,h.AOGUID
    ,h.POSTALCODE
    ,concat(
        case 
            when h.ESTSTATUS = 1 then N'влд '
            when h.ESTSTATUS in (2, 3, 5) then N'д '
            else ''
        end + h.HOUSENUM
        ,isnull(' к ' + h.BUILDNUM, '')
        ,isnull(case
                    when h.STRSTATUS = 1
                    then N' стр '
                    else N' сооружение '
                end + h.STRUCNUM, '')
        ) as HOUSENUM

into dict.houseactive2
from dict.house h
inner join m on m.houseguid = h.HOUSEGUID
    and m.enddate = h.ENDDATE
    and h.enddate > getdate()
    and h.STARTDATE < getdate()
;

alter table dict.houseactive2
alter column HOUSEGUID uniqueidentifier not null
/


ALTER TABLE dict.houseactive ADD  CONSTRAINT [PK_houseactiveaoguid] PRIMARY KEY 
([HOUSEGUID] ASC)

create FULLTEXT INDEX  ON dict.houseactive (HOUSENUM) KEY INDEX PK_houseactiveaoguid
WITH (CHANGE_TRACKING AUTO)

select count(*)
from dict.houseactive

create index houseactive_AOGUID_idx on dict.houseactive(AOGUID)
/
--drop table if exists dict.hierarchy2
;

with h (aoguid, name, parentguid, aolevel, CENTSTATUS, a.REGIONCODE, POSTALCODE) as 
(
    select
        a.aoguid
        ,cast(a.FORMALNAME + ' ' + a.SHORTNAME as nvarchar(512)) as name
        ,cast(null as nvarchar(255)) as parentguid
        ,a.aolevel
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
        ,cast(h.name + ', ' + a.FORMALNAME + ' ' + a.SHORTNAME as nvarchar(512))
        ,a.parentguid
        ,a.aolevel
        ,a.CENTSTATUS
        ,a.REGIONCODE
        ,a.POSTALCODE
    from dict.addrobj a
    inner join h on h.aoguid = a.PARENTGUID
    where a.ACTSTATUS = 1
)

select *
into dict.hierarchy2
from h
;

alter table dict.hierarchy2
add hasHouse bit default 0
;

update h
set hasHouse = 1
from dict.hierarchy2 h
where h.aoguid in (select aoguid from #lasthouseparent)
/


alter  table dict.hierarchy2
alter column aoguid uniqueidentifier not null
go

ALTER TABLE dict.hierarchy2 ADD  CONSTRAINT [PK_hierarchy2_aoguid] PRIMARY KEY CLUSTERED
([aoguid] ASC)
;

create FULLTEXT INDEX  ON dict.hierarchy2 (name) KEY INDEX PK_hierarchy2_aoguid
WITH (CHANGE_TRACKING AUTO)

/

select*
from dict.hierarchy2
where aoguid = 'bb550631-d5c3-496d-95f4-6114e0eb1499'
