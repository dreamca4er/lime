drop table if exists dict.houseactivePrev
GO

drop table if exists [dict].[houseactiveTmp]
GO

CREATE TABLE [dict].[houseactiveTmp]  (
    [id]            int identity(1, 1) NOT NULL,
    [HOUSEGUID]     nvarchar(255) NULL,
    [AOGUID]        nvarchar(255) NULL,
    [POSTALCODE]    nvarchar(255) NULL,
    [address]       nvarchar(316) NULL,
    [regioncode]    int NULL,
    [centstatus]    smallint NULL
)
;

with m as 
(
select
    HOUSEGUID
    ,max(ENDDATE) as ENDDATE
from dict.house
group by HOUSEGUID
)

insert into dict.houseactiveTmp(houseguid, aoguid, postalcode, address, regioncode, centstatus)
select
    h.houseguid
    ,h.aoguid
    ,h.postalcode
    ,hi.name
    + ', '
    + concat(
        case 
            when h.ESTSTATUS = 1 then N'влд '
            when h.ESTSTATUS in (2, 3, 5) then N'д '
            else ''
        end + h.HOUSENUM
        ,isnull(N' к ' + h.BUILDNUM, '')
        ,isnull(case
                    when h.STRSTATUS = 1
                    then N' стр '
                    else N' сооружение '
                end + h.STRUCNUM, '')
        ) as address
    ,cast(hi.regioncode as int) as regioncode
    ,cast(hi.centstatus as smallint) as centstatus
from dict.house h
inner join dict.hierarchy hi on h.AOGUID = hi.AOGUID
inner join m on m.houseguid = h.HOUSEGUID
    and m.enddate = h.ENDDATE
    and h.enddate > getdate()
    and h.STARTDATE < getdate()
;

declare
    @tmstmp nvarchar(20) = format(getdate(), 'yyyyMMdd_HHmmss')
;

exec ('alter table [dict].[houseactiveTmp] add constraint PK_houseactiveTmp' + @tmstmp + '_id primary key clustered(id)')
;

exec ('create unique index uq_houseactiveTmp' + @tmstmp + '_houseguid_idx on [dict].[houseactiveTmp](houseguid)')
;

exec ('create index houseactiveTmp' + @tmstmp + '_aoguid_idx ON [dict].[houseactiveTmp]([AOGUID])')
;

exec ('create fulltext index  on dict.houseactiveTmp (address) key index PK_houseactiveTmp' + @tmstmp + '_id with (change_tracking auto, stoplist off)')
;

exec dict.sp_WaitForFullTextIndexing 'test_catalog'
;

exec sp_rename 'dict.houseactive', 'houseactivePrev', 'object'
;
exec sp_rename 'dict.houseactiveTmp', 'houseactive', 'object'
;

drop table if exists dict.[houseactiveTmp]
GO