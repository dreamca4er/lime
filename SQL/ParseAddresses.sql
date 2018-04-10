set nocount on
;

/*
drop table if exists dbo.NoAddressList 
;

drop table if exists dbo.SearchResult
;

drop table if exists #tmp
;

create table dbo.NoAddressList 
(
    AddressId int
    ,AddressStr nvarchar(400)
    ,houseguid uniqueidentifier
    ,aoguid uniqueidentifier
    ,area nvarchar(500)
    ,FixedAddress nvarchar(500)
    ,isProcessed bit
    ,isProcessedWithoutHouse bit default(0)
)
GO

create table dbo.SearchResult
(
    AddressId int
    ,houseguid uniqueidentifier
    ,aoguid uniqueidentifier
    ,postalcode nvarchar(6)
    ,address nvarchar(400)
    ,regioncode nvarchar(2)
    ,ishouse bit
)
GO

create table #tmp
(
    houseguid uniqueidentifier
    ,aoguid uniqueidentifier
    ,postalcode nvarchar(6)
    ,address nvarchar(400)
    ,regioncode nvarchar(2)
    ,ishouse bit
)
GO

create table dbo.SearchResultWithoutHouse
(
    AddressId int
    ,houseguid uniqueidentifier
    ,aoguid uniqueidentifier
    ,postalcode nvarchar(6)
    ,address nvarchar(400)
    ,regioncode nvarchar(2)
    ,ishouse bit
)
GO

insert into dbo.NoAddressList 
(
    AddressId
    ,AddressStr
    ,houseguid
    ,aoguid
    ,isProcessed
)
select
    id as AddressId
    ,AddressStr
    ,BuildingId as houseguid
    ,LocationId as aoguid 
    ,0
from client.Address a
where LocationId = cast(0x0 as uniqueidentifier)
    and not exists
                (
                    select 1 from dbo.NoAddressList l
                    where a.id = l.AddressId
                )
;
update a
set area = substring(AddressStr, charindex('(', AddressStr), charindex(')', AddressStr) - charindex('(', AddressStr) + 1)
from dbo.NoAddressList a
where 
        AddressStr like N'%(%область%)%'
        or AddressStr like N'%(%край%)%'
        or AddressStr like N'%(%респ%)%'
        or AddressStr like N'%(%округ%)%'
        or AddressStr like N'%(%санкт%)%'
        or AddressStr like N'%(%моск%)%'
;

update a
set FixedAddress = 
    isnull(
    replace(replace(replace(replace((
        select
            rtrim(ltrim(reverse(value))) as v
        from string_split(reverse(replace(replace(area, '(', ''), ')', '')), ',') a
        for json path, without_array_wrapper
    ), '{', ''), '}', ''), '"v":"', ''), '"', '')
    + ' '
    + replace(AddressStr, area, ''), AddressStr)
from dbo.NoAddressList a

*/

/*
declare
    @id int
    ,@i int = 0
    ,@adr nvarchar(500)
;

WHILE @i < 4200
BEGIN  
    truncate table #tmp
    ;
    
    select top 1 @id = AddressId
    from dbo.NoAddressList 
    where isProcessed = 0
    ;
    
    select @adr = (select FixedAddress from dbo.NoAddressList where AddressId = @id)
    ;
    
    insert into #tmp
    exec fias.dict.spgetaddress @adr
    ;

    insert into dbo.SearchResult 
    select @id, *
    from #tmp
    ;
    
    update a
    set isProcessed = 1
    from dbo.NoAddressList a
    where AddressId = @id
    ;
    
    truncate table #tmp
    ;
    
    set @i = @i + 1
END
*/

declare
    @id int
    ,@i int = 0
    ,@adr nvarchar(500)
;

WHILE @i < 2000
BEGIN  
    truncate table #tmp
    ;
    
    select top 1 @id = AddressId
    from dbo.NoAddressList  nal
    where isProcessedWithoutHouse = 0
        and not exists 
                    (
                        select 1 from dbo.SearchResult sr
                        where sr.AddressId = nal.AddressId
                    )
    ;
    
    select @adr = (select replace(FixedAddress, right(FixedAddress, charindex(',', reverse(FixedAddress))), '') from dbo.NoAddressList where AddressId = @id)
    ;
    
    insert into #tmp
    exec fias.dict.spgetaddress1 @adr
    ;

    insert into dbo.SearchResultWithoutHouse
    select @id, *
    from #tmp
    ;
    
    update a
    set isProcessedWithoutHouse = 1
    from dbo.NoAddressList a
    where AddressId = @id
    ;
    
    truncate table #tmp
    ;
    
    set @i = @i + 1
END

/*
delete from dbo.SearchResultWithoutHouse
update dbo.NoAddressList set isProcessedWithoutHouse = 0
*/

select
    a.AddressType
    ,isProcessedWithoutHouse
    ,count(*) as cnt
    ,round(count(*) * 1.0 / sum(count(*)) over (), 4) * 100
from dbo.NoAddressList nal
inner join client.Address a on a.Id = nal.AddressId 
    and not exists 
                (
                    select 1 from dbo.SearchResult sr
                    where sr.AddressId = nal.AddressId
                )
group by a.AddressType, nal.isProcessedWithoutHouse

select cnt, count(*)
from 
(
    select count(*) cnt
    from dbo.SearchResultWithoutHouse a
    group by AddressId
) a
group by cnt
order by cnt

