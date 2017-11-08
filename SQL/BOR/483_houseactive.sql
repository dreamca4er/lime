CREATE TABLE [dict].[houseactive]  (
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

select
    row_number() over (order by h.AOGUID) as id
    ,h.houseguid
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
into dict.houseactive
from dict.house h
inner join dict.hierarchy hi on h.AOGUID = hi.AOGUID
inner join m on m.houseguid = h.HOUSEGUID
    and m.enddate = h.ENDDATE
    and h.enddate > getdate()
    and h.STARTDATE < getdate()
;

alter table [dict].[houseactive] add constraint PK_houseactive_id primary key clustered(id)
;

create unique index uq_houseactive_houseguid_idx on [dict].[houseactive](houseguid)
;

create index houseactive_aoguid_idx ON [dict].[houseactive]([AOGUID])
;

create fulltext index  on dict.houseactive (address) key index PK_houseactive_id
with (change_tracking auto)
;


SELECT
    FULLTEXTCATALOGPROPERTY(cat.name,'ItemCount') AS [ItemCount]
    ,FULLTEXTCATALOGPROPERTY(cat.name,'UniqueKeyCount') AS [UniqueKeyCount]
    ,FULLTEXTCATALOGPROPERTY(cat.name,'MergeStatus') AS [MergeStatus]
    ,FULLTEXTCATALOGPROPERTY(cat.name,'PopulateCompletionAge') AS [PopulateCompletionAge]
    ,FULLTEXTCATALOGPROPERTY(cat.name,'PopulateStatus') AS [PopulateStatus]
    ,FULLTEXTCATALOGPROPERTY(cat.name,'ImportStatus') AS [ImportStatus]
    ,FULLTEXTCATALOGPROPERTY(cat.name,'IndexSize') AS [IndexSize]
FROM sys.fulltext_catalogs AS cat


