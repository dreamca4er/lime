declare
    @tmstmp nvarchar(20) = format(getdate(), 'yyyyMMdd_HHmmss')
;

drop table if exists dict.hierarchyPrev
;

drop table if exists dict.[hierarchyTmp]
;

drop table if exists #tmp2
;

CREATE TABLE [dict].[hierarchyTmp]  ( 
    [id]            int IDENTITY(1,1) NOT NULL,
    [aoguid]        nvarchar(255) NULL,
    [name]          nvarchar(255) NULL,
    [parentguid]    nvarchar(255) NULL,
    [centstatus]    int NULL,
    [regioncode]    nvarchar(255) NULL,
    [postalcode]    nvarchar(255) NULL,
    [aolevel]       int NULL,
    placementGuid uniqueidentifier
)
;

with h (aoguid, name, parentguid, centstatus, regioncode, postalcode, aolevel, placementGuid) as 
(
    select
        a.aoguid
        ,cast(a.FORMALNAME + ' ' + a.SHORTNAME as nvarchar(255)) name
        ,cast(null as nvarchar(255)) as parentguid
        ,cast(a.centstatus as smallint) as centstatus
        ,cast(a.regioncode as int) as regioncode
        ,a.postalcode
        ,a.aolevel
        ,aoguid as regionGuid
    from dict.addrobj a
    where a.ACTSTATUS = 1
        and a.AOLEVEL = 1

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
            when a.aolevel in (1, 3, 4)
            then a.aoguid
            else h.placementGuid
        end
    from dict.addrobj a
    inner join h on h.aoguid = a.PARENTGUID
    where a.ACTSTATUS = 1
)

insert into dict.hierarchyTmp (aoguid,name,parentguid,centstatus,regioncode,postalcode,aolevel, placementGuid)
select aoguid,name,parentguid,centstatus,regioncode,postalcode,aolevel, placementGuid 
from h
;

-- Нуходим данные по дублям
select *
into #tmp2
from dict.hierarchyTmp
where name in
            (
                select t.name from dict.hierarchyTmp t
                group by t.name
                having count(*) > 1
            )
;

exec ('create index hierarchyTmp' + @tmstmp + '_parentguid_idx on dict.hierarchyTmp(parentguid)')
;

-- Находим из дублей те, у которого к некоторому потомку (или к самому дублю относятся дома)
with a (initguid, currguid, hashouse) as 
(
    select
        aoguid as initguid
        ,aoguid as currguid
        ,case
            when exists 
                    (
                        select 1 from dict.house h
                        where h.AOGUID = t.aoguid
                            and h.STARTDATE < getdate()
                            and h.ENDDATE > getdate()
                    )
            then 1
            else 0
        end as hashouse
    from #tmp2 t

    union all

    select
        a.initguid
        ,hi.aoguid
        ,case
            when exists 
                    (
                        select 1 from dict.house h
                        where h.AOGUID = hi.aoguid
                            and h.STARTDATE < getdate()
                            and h.ENDDATE > getdate()
                    )
            then 1
            else 0
        end
    from a
    inner join dict.hierarchyTmp hi on a.currguid = hi.parentguid
    where a.hashouse = 0
)

delete
from dict.hierarchyTmp
where name in (select name from #tmp2)
    and not exists 
                (
                    select 1
                    from a
                    where a.initguid = hierarchyTmp.aoguid
                        and a.hashouse = 1
                )
;

exec ('create index hierarchyTmp' + @tmstmp + '_aoguid_idx on dict.hierarchyTmp(aoguid)')
;

exec ('alter table dict.hierarchyTmp add constraint pk_hierarchyTmp' + @tmstmp + '_id primary key (id)')
;

exec ('create fulltext index on dict.hierarchyTmp (name) key index pk_hierarchyTmp' + @tmstmp + '_id with (change_tracking auto, stoplist off)')
;

exec ('alter table dict.hierarchyTmp add constraint uq_hierarchyTmp' + @tmstmp + '_aoguid unique(aoguid)')
;

exec dict.sp_WaitForFullTextIndexing 'test_catalog'
;

exec sp_rename 'dict.hierarchy', 'hierarchyPrev', 'object'
;
exec sp_rename 'dict.hierarchyTmp', 'hierarchy', 'object'
;

drop table if exists dict.[hierarchyTmp]
GO