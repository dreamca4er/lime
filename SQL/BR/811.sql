create or alter procedure Fias.dict.sp_SplitAddress(@AddressStr nvarchar(1000), @index nvarchar(6), @BuildingId uniqueidentifier, @LocationId uniqueidentifier) as
begin
declare
    @JSONedLocationId nvarchar(100)
    ,@JSONedBuilding nvarchar(100)
    ,@region nvarchar(2)
    ,@regionName nvarchar(255)
    ,@city nvarchar(255)
    ,@street nvarchar(255)
    ,@house nvarchar(255)
    ,@OkatoRegion nvarchar(2)
    ,@building nvarchar(255)
    ,@block nvarchar(255)
;

declare @HouseInfo table
(
    houseguid uniqueidentifier
    ,housenum nvarchar(255)
    ,strucnum nvarchar(255)
    ,buildnum nvarchar(255)
    ,postalcode nvarchar(6)
)

set @JSONedLocationId = '["' + cast(@LocationId as nvarchar(36)) + '"]'
;

set @JSONedBuilding = '["' + cast(@BuildingId as nvarchar(36)) + '"]'
;

drop table if exists #h
;

drop table if exists #FiasPostalRegion
;

create table #h
(
    initialGuid uniqueidentifier
    ,currentGuid uniqueidentifier
    ,name nvarchar(200)
    ,aolevel int
    ,okato nvarchar(20)
)

insert into #h
exec fias.dict.spGetPlaceHierarchy @JSONedLocationId
;

with FiasPostalRegion as 
(
    select postalcode, cast(regioncode as nvarchar(2)) as regioncode
    from dict.houseactive
    where houseguid = @BuildingId
        and (postalcode != '' or regioncode != '')
    
    union
    
    select postalcode, cast(regioncode as nvarchar(2)) as regioncode
    from dict.hierarchy
    where aoguid = @LocationId
        and (postalcode != '' or regioncode != '')
)

select *
into #FiasPostalRegion
from FiasPostalRegion
;

set @index = coalesce
(
    @index
    ,(
    select top 1 postalcode
    from #FiasPostalRegion
    where postalcode != ''
    ),
    (    
    select '000000'
    from (values (1)) as a(b)
    where not exists (select 1 from #FiasPostalRegion where postalcode != '')
    )
)
;

set @region = coalesce
(
    (
    select top 1 regioncode
    from #FiasPostalRegion
    where regioncode != ''
    ),
    (    
    select '00'
    from (values (1)) as a(b)
    where not exists (select 1 from #FiasPostalRegion where regioncode != '')
    )
)
;

set @city =  replace(replace(replace(coalesce
(
    (    
    select name    
    from #h
    where aolevel in (3, 4, 5, 6)
    order by aolevel
    for json auto, without_array_wrapper
    )
    ,(
    select name
    from #h
    where aolevel in (1, 3)
        and not exists
                (
                    select *
                    from #h
                    where aolevel in (4, 5, 6)
                )
    order by aolevel
    for json auto, without_array_wrapper
    )
), '"name":', ''), '{"', ''), '"}', '')
;

set @street = replace(replace(replace(coalesce
(
    (
    select name    
    from #h
    where aolevel in (7, 65, 90, 91)
    order by aolevel
    for json auto, without_array_wrapper
    ),
    (
    select name
    from #h
    where currentGuid = @LocationId
        and not exists
                (
                    select *
                    from #h
                    where aolevel in (7, 65, 90, 91)
                )
    order by aolevel
    for json auto, without_array_wrapper
    )
), '"name":', ''), '{"', ''), '"}', '')
;

insert @HouseInfo
exec fias.dict.spGetBuildingInfo @JSONedBuilding
;

select @house = left(housenum, charindex(N'к', housenum) - 2)
from @HouseInfo
;

select @building = strucnum
from @HouseInfo
;

select @block = buildnum
from @HouseInfo
;

select @house = isnull(@house, rtrim(ltrim(concat(N'д ' + housenum, ' ', N'к ' + buildnum, ' ', N'стр ' + strucnum))))
from fias.dict.houseactive
where houseguid = @BuildingId
;

set @regionName = 
(
select top 1 name
from fias.dict.hierarchy
where aolevel in (1, 2)
    and regioncode = isnull(@region, '77')
)
;

set @OkatoRegion =
(
    select top 1 left(OKATO, 2)
    from dict.addrobj
    where aoguid = @LocationId
)

select 
    @index as PostalCode
    ,isnull(@OkatoRegion, '45') as OkatoRegion
    ,isnull(@region, '77') as Region
    ,isnull(@regionName, N'Москва г') as RegionName
    ,isnull(@city, N'Москва г') as City
    ,isnull(@street, N'Профсоюзная ул') as Street
    ,coalesce(@house, rtrim(ltrim(right(@AddressStr, charindex(',', reverse(@AddressStr)) - 1))), '1') as House
    ,@building as Building
    ,@block as Block
;
end
--
--/
--exec fias.dict.sp_SplitAddress N'Омская обл, Омск г, Краснознаменная ул, д 26 к 1', '644013', '094203C8-B18C-44C4-9006-ED4DA8F30E57', '86A67CF5-B40D-4D18-B991-F08608A8F327'
