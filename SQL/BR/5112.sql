declare @pack int = 13, @size int = 200000; 

update top (@size) a set ModifiedBy = 0x44, Data =
--    select top (@size)
--        a.id 
--        ,a.clientid
--    ,
    replace(replace(replace(replace((
        select
            replace((
                select 
                    d.Region as region_with_type
                    , d.Area as area_with_type
                    , d.City as city_with_type
                    , d.Settlement as settlement_with_type
                    , d.Street as street_with_type
                    , coalesce(a.PostCode, ha.postalcode, r.postalcode, d.PostalCode, '600000') as postal_code
                    , isnull(ha.housenum, reverse(substring(reverse(a.AddressStr), 1, charindex(',', reverse(a.AddressStr)) - 2))) as house
                    , coalesce(ha.buildnum + ' ' + ha.strucnum, ha.buildnum, ha.strucnum) as block
                    , d.OKATO as okato
                    , d.OKTMO as oktmo
                    , d.RegionKLADR as region_kladr_id
                from (select 1) b(v)
                for json auto, without_array_wrapper
            ), '\"', '`') as data
            , replace(a.AddressStr, '"', '`') as unrestricted_value
        from (select 1) b(v)
        for json auto, without_array_wrapper
    ), '"{', '{'), '}"', '}'), '\"', '"'), '`', '\"')-- as Data
from client.Address a
left join fias.dict.hierarchy r on r.regioncode = cast(a.RegionId as nvarchar(3)) 
    and r.aolevel = 1
left join fias.dict.houseactive ha on ha.houseguid = a.BuildingId
--outer apply
--(
--    select top 1
--        a2.id
--        ,a2.Data
--    from client.Address a2
--    where a2.LocationId = a.LocationId
--        and a2.id != 538
--    order by a2.id desc
--) a2
outer apply
(
    select top 1
        a2.Data
    from #oth a2
    where a2.LocationId = a.LocationId
) a2
outer apply openjson(a2.Data)
with
(
    Region nvarchar(100) '$.data.region_with_type'
    , Area nvarchar(100) '$.data.area_with_type'
    , City nvarchar(100) '$.data.city_with_type'
    , Settlement nvarchar(100) '$.data.settlement_with_type'
    , Street nvarchar(100) '$.data.street_with_type'
    , PostalCode nvarchar(100) '$.data.postal_code'
    , House nvarchar(100) '$.data.house'
    , HouseType nvarchar(100) '$.data.house_type'
    , Block nvarchar(100)'$.data.block'
    , BlockType nvarchar(100)'$.data.block_type'
    , OKATO nvarchar(100) '$.data.okato'
    , OKTMO nvarchar(100) '$.data.oktmo'
    , RegionKLADR nvarchar(50) '$.data.region_kladr_id'
) d
where a2.Data is not null
    and a.Data is null
    and a.AddressStr != ''
    and a.id >= (@pack - 1) * @size
    and a.id < @pack * @size
;

declare 
    @packsleft int = (select (max(id) - @pack * @size) * 1.0 / @size from client.Address a where data is null)
    ,@PctEmpty numeric(5, 2) = (select 1 - count(data) * 1.0 / count(*) as PctEmpty from client.Address a)
;

print 'pack: ' + format(@pack, '#,#0')
print '@PctEmpty: ' + format(@PctEmpty, '#,#0.##%')
print '@packsleft: ' + format(@packsleft, '#,#0')

/
drop table if exists #oth
;

select
    a.id
    ,a.LocationId
    ,a.data
into #oth
from "BOR-MANGO-DB".Borneo.client.address a
where Data is not null

create index IX_oth_LocationId on #oth(LocationId)
/

declare @pack int = 07, @size int = 400000; 
  
--select
--    a.id
--    , a.ClientId
--    , a.AddressStr
--    , a.Data
--    , json_modify(Data, '$.data.house', replace(json_value(Data, '$.data.house'), '\/', '/'))
--    , json_value(Data, '$.data.house')
update a set Data = replace(Data, '\/', '/')
from client.address a
where Data like '%\/%'
    and a.id >= (@pack - 1) * @size
    and a.id < @pack * @size
;

print 'pack: ' + format(@pack, '#,#0')
/
declare @pack int = 14, @size int = 200000; 
;

select top 1 *
from client.vw_address a
where House is null
    and Region is not null
    and a.AddressId >= (@pack - 1) * @size
    and a.AddressId < @pack * @size

print 'pack: ' + format(@pack, '#,#0')
/

select
    a.*
into #Address
from client.Address a
where a.BuildingId != 0x00
    and a.Data is null

drop table if exists #Address
;

select
    a.*
into #Address
from client.Address a
where a.LocationId != 0x00
    and a.Data is null
/

alter table #Address add primary key (id)

/
declare @pack int = 14, @size int = 200000
;

with cte (AddressId, Aolevel, Name, Ord, Aoguid, postalcode) as 
(
select
    id
    , -1 as Aolevel
    , cast(AddressStr as nvarchar(500)) as Name
    , 1 as Ord
    , LocationId as Aoguid
    , cast(a.PostCode as nvarchar(6)) as postalcode
from #Address a
where a.id >= (@pack - 1) * @size
    and a.id < @pack * @size

union all

select
    cte.AddressId
    , h.aolevel
    , cast(h.name as nvarchar(500)) as Name
    , cte.Ord + 1 as Ord
    , h.parentguid
    , cast(h.postalcode as nvarchar(6)) as postalcode
from cte
inner join fias.dict.hierarchy h on h.aoguid = cte.Aoguid
)

-- create index IX_Parsed on #Parsed(AddressId, Ord)

insert #Parsed
select *
--into #Parsed
from cte
where not exists 
    (
        select 1 from #Parsed p
        where cte.AddressId = p.AddressId
    )
print 'pack: ' + format(@pack, '#,#0')
/
declare @pack int = 01, @size int = 200000
;

--select *
--from client.Address
--where id = 1227913
        
with a as 
(
    select
        p.Addressid
        , adr.ClientId
    --    , ln.LevelName
    --    , p.Aolevel
    --    , p.Ord
    --    , p.Aoguid
        , max(case when p.Aolevel = -1 then ha.houseguid end) as houseguid
        , max(case when p.aolevel = -1 then p.Name end) as StartAddress
        , max(case when p.Aolevel = 1 then ln.LevelName end) as region_with_type
        , max(case when p.Aolevel = 3 then ln.LevelName end) as area_with_type
        , case
            when max(case when p.Aolevel = 4 then ln.LevelName end) is null
                and max(case when p.Aolevel = 6 then ln.LevelName end) is null
                and max(case when p.Aolevel = 1 then ln.LevelName end) in (N'Москва г', N'Санкт-Петербург г')
            then max(case when p.Aolevel = 1 then ln.LevelName end)
            else max(case when p.Aolevel = 4 then ln.LevelName end)
        end as city_with_type
        , max(case when p.Aolevel = 6 then ln.LevelName end) as settlement_with_type
        , max(case when p.Aolevel = 7 then ln.LevelName end) as street_with_type
        , max(case when p.Aolevel = -1 then p.PostalCode end) as postal_code
        , max(case when p.Aolevel = -1 then f.OKATO end) as okato
        , max(case when p.Aolevel = -1 then f.OKTMO end) as oktmo
        , max(case when p.Aolevel = -1 then f.REGIONCODE end) as region_kladr_id
        , isnull(max(N'д ' + ha.housenum), rtrim(ltrim(right(max(case when p.aolevel = -1 then p.Name end), charindex(',', reverse(max(case when p.aolevel = -1 then p.Name end))) - 1)))) as house
        , max(coalesce(N'к ' + ha.buildnum + ' ' + N'стр ' + ha.strucnum, N'к ' + ha.buildnum, N'стр ' + ha.strucnum)) as block
    from #Parsed p
    left join client.Address adr on adr.id = p.AddressId
    left join client.vw_address va on va.AddressId = adr.Id
    left join #Parsed p2 on p.AddressId = p2.AddressId
        and p.Ord = p2.Ord - 1
    left join fias.dict.houseactive ha on ha.houseguid = adr.BuildingId
    outer apply
    (
        select top 1
            OKATO
            , OKTMO
            , REGIONCODE
        from fias.dict.addrobj a
        where a.AOGUID = p.Aoguid
            and p.Ord = 1
    ) f
    outer apply
    (
        select isnull(replace(p.Name, p2.Name + ', ', ''), P.name) as LevelName
    ) ln
    where p.AddressId >= (@pack - 1) * @size
        and p.AddressId < @pack * @size
        and adr.data is null
    group by p.Addressid, adr.ClientId
)

--select top 100 
--    a.Addressid
--    , a.ClientId
--    , region_with_type
--    , area_with_type
--    , city_with_type
--    , settlement_with_type
--    , street_with_type
--    , postal_code
--    , house
--    , block
--    , okato
--    , oktmo
--    , region_kladr_id
--    , StartAddress as unrestricted_value
--    , 
    update top (@size) adr set ModifiedBy = 0x44, ModifiedOn = getdate(), Data = 
    replace(replace(replace(replace((
        select
            replace((
                select 
                    region_with_type
                    , area_with_type
                    , city_with_type
                    , settlement_with_type
                    , street_with_type
                    , postal_code
                    , house
                    , block
                    , okato
                    , oktmo
                    , region_kladr_id
                from (select 1) b(v)
                for json auto, without_array_wrapper
            ), '\"', '`') as data
            , replace(a.StartAddress, '"', '`') as unrestricted_value
        from (select 1) b(v)
        for json auto, without_array_wrapper
    ), '"{', '{'), '}"', '}'), '\"', '"'), '`', '\"')-- as Data
from a
inner join client.address adr on adr.id = a.AddressId
where 1=1
    and adr.Data is null
;

print 'pack: ' + format(@pack, '#,#0') 
/
declare @pack int = 12, @size int = 200000
;
select 
    adr.AddressId
    ,adr.ClientId
    ,adr.Address
    ,'https://limeadmin.lime.local/clients/' + cast(a.ClientId as nvarchar(10)) + '/details' as url
from client.address a
inner join client.vw_address adr on adr.AddressId = a.id
where 1=1
--    and a.ModifiedBy = 0x44
--    and a.ModifiedOn =
--        (
--            select max(a2.ModifiedOn)
--            from client.Address a2
--            where a2.ModifiedBy = 0x44
--        )
    and
    (
        adr.house is null
        or
        adr.Region is null
        or
        adr.PostalCode is null
    )
    and a.Data > ''
    and a.id >= (@pack - 1) * @size
    and a.id < @pack * @size
order by a.ClientId
/
drop table if exists #stat
;

create table #stat
(
    pack int not null primary key
    , cnt int
    , DataCnt int
    , houseCnt int
    , RegionCnt int
    , PostalCodeCnt int
    , dt datetime2
)
;
/
declare @pack int = 14, @size int = 200000
;

insert #stat -- drop table #stat -- select * from #stat
select 
    @pack as pack
    , count(*) as cnt
    , count(Data) as DataCnt
    , count(a.house) as houseCnt
    , count(a.Region) as RegionCnt
    , count(a.PostalCode) as PostalCodeCnt
    , getdate() as dt
from client.address adr
inner join client.vw_Address a on a.AddressId = adr.id
where adr.id >= (@pack - 1) * @size
    and adr.id < @pack * @size
;

print 'pack: ' + format(@pack, '#,#0') 

/
declare @pack int = 14, @size int = 200000
;

select
    a.*
    , rtrim(ltrim(right(a.AddressStr, charindex(',', reverse(a.AddressStr)) - 1)))
--update a set Data = json_modify(a.Data, '$.data.house', rtrim(ltrim(right(a.AddressStr, charindex(',', reverse(a.AddressStr)) - 1))))
--update a set a.AddressStr = replace(a.AddressStr, N'сооружение', N'стр')
from client.Address a
inner join client.vw_address va on va.AddressId = a.id
where 1=1
    and a.id >= (@pack - 1) * @size
    and a.id < @pack * @size
    and va.house is null
    and a.AddressStr > ''
;

print 'pack: ' + format(@pack, '#,#0') 
/*
select *
from client.Address
where id = 1180386
*/
/
select count(*) -- update a set RegionId = va.RegionCode
from client.Address a
inner join client.vw_address va on va.AddressId = a.id
where a.RegionId is null
    and va.RegionCode is not null
/

declare @pack int = 14, @size int = 200000
;

select
    d.Region 
    , d.Area  
    , d.City  
    , d.Settlement  
    , d.Street  
    , isnull(d.PostalCode, a.PostCode) as PostalCode
    , d.House  
    , d.HouseType  
    , d.Block  
    , d.BlockType  
    , d.OKATO  
    , d.OKTMO  
    , d.RegionKLADR
into #a
from client.address a
outer apply openjson(a.Data)
with
(
    Region nvarchar(100) '$.data.region_with_type'
    , Area nvarchar(100) '$.data.area_with_type'
    , City nvarchar(100) '$.data.city_with_type'
    , Settlement nvarchar(100) '$.data.settlement_with_type'
    , Street nvarchar(100) '$.data.street_with_type'
    , PostalCode nvarchar(100) '$.data.postal_code'
    , House nvarchar(100) '$.data.house'
    , HouseType nvarchar(100) '$.data.house_type'
    , Block nvarchar(100)'$.data.block'
    , BlockType nvarchar(100)'$.data.block_type'
    , OKATO nvarchar(100) '$.data.okato'
    , OKTMO nvarchar(100) '$.data.oktmo'
    , RegionKLADR nvarchar(50) '$.data.region_kladr_id'
) d
GO
where 1=1
    and a.id >= (@pack - 1) * @size
    and a.id < @pack * @size]
/

declare @pack int = 1, @size int = 200000; 

drop table if exists #a
;

select *
into #a
from client.vw_address a
where 1=1
    and a.AddressId >= (@pack - 1) * @size
    and a.AddressId < @pack * @size
;
/
-- AddressId,ClientId,AddressType,Address,Region,RegionCode,City,PostalCode,Street,House,Block,HouseAndBlock,Apartment,OKATO,OKTMO

-- update a set AddressStr = replace(AddressStr, '  ', ' ')
-- update a set AddressStr = replace(AddressStr, N'д д владение', N'д')
select 
    a.ClientId
    , a.AddressStr
    , replace(replace(rtrim(ltrim(p.h)), ', ', ' '), '  ', ' ')
    , json_modify(a.Data, '$.data.house', replace(replace(rtrim(ltrim(p.h)), ', ', ' '), '  ', ' '))
-- update a set Data = json_modify(a.Data, '$.data.house', replace(replace(rtrim(ltrim(p.h)), ', ', ' '), '  ', ' ')), ModifiedOn = getdate(), ModifiedBy = 0x44
from #a 
inner join client.Address a on a.id = #a.AddressId
inner join client.vw_address va on va.AddressId = a.id
outer apply
(
    select reverse(left( reverse(a.AddressStr), patindex(N'% д ,%', reverse(a.AddressStr)) + 1)) as h
) p
where #a.house like N'к%'
    and a.AddressStr like N'% д %'

/

select
    City
   , Street
   , count(*)
from #a va
group by 
    City
   , Street
   
/

declare @pack int = 14, @size int = 200000; 

drop table if exists #a
;

select *
into #a
from client.vw_address a
where 1=1
    and a.AddressId >= (@pack - 1) * @size
    and a.AddressId < @pack * @size
;
/
-- AddressId,ClientId,AddressType,Address,Region,RegionCode,City,PostalCode,Street,House,Block,HouseAndBlock,Apartment,OKATO,OKTMO

-- update a set AddressStr = replace(AddressStr, '  ', ' ')
-- update a set AddressStr = replace(AddressStr, N'д д владение', N'д')
/*
select 
    a.ClientId
    , a.AddressStr
    , p7.h
    , json_modify(a.Data, '$.data.house', p7.h)
-- update a set Data = json_modify(a.Data, '$.data.house', p7.h), ModifiedOn = getdate(), ModifiedBy = 0x44
from #a 
inner join client.Address a on a.id = #a.AddressId
inner join client.vw_address va on va.AddressId = a.id
outer apply
(
    select reverse(left( reverse(a.AddressStr), patindex(N'% д ,%', reverse(a.AddressStr)) + 1)) as h
) p
outer apply
(
    select replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(rtrim(ltrim(lower(p.h)))
            , ', ', ' ')
            , '  ', ' ')
            , N'корпус', N'к')
            , N'корп', N'к')
            , N'дом', N'д')
            , N'владение', N'влд')
            , N'строение', N'стр')
            , N'сооружение', N'соор')
            , N'д д', N'д')
            , N'д влд', N'д')
            , N'д стр', N'д')
            , N'к стр', N'к')
            , N' к к ', N' к ')
            , N'кв', N'к')
                as h
) p2
outer apply
(
    select iif(right(p2.h, 3) = left(right(p2.h, 7), 3), replace(p2.h, right(p2.h, 3) + ' ' + right(p2.h, 3), right(p2.h, 3)), p2.h) as h
) p3
outer apply
(
    select iif(p3.h like N'%[0-9а-Я]литер[0-9а-Я]%', replace(p3.h, N'литер', N' литер '), p3.h) as h
) p4
outer apply
(
    select iif(right(p4.h, 2) = N' к', left(p4.h, len(p4.h) - 2), p4.h) as h
) p5
outer apply
(
    select iif(right(p4.h, 4) = N' к 0', left(p4.h, len(p4.h) - 4), p4.h) as h
) p6
outer apply
(
    select iif(right(p6.h, 4) = left(right(p6.h, 9), 4), replace(p6.h, right(p6.h, 4) + ' ' + right(p6.h, 4), right(p6.h, 4)), p6.h) as h
) p7
where #a.house like N'к%'
    and a.AddressStr like N'% д %'
order by len(p7.h) desc
*/

select
    RegionCode
    , count(*)
from #a
group by RegionCode

select
    Region
    , count(*)
from #a
group by Region

select
    city
    , count(*)
from #a
group by city

select
    street
    , count(*)
from #a
group by street
/
drop table if exists #toparse
;

select 
    AddressId
    , Address
    , RegionCode
into #toparse
from client.vw_address
where city = ''
/
select *
from #toparse



create table dbo.ParsedAddresses
(
    AddressId int
    , houseguid uniqueidentifier
    , aoguid uniqueidentifier
    , postalcode nvarchar(6)
    , address nvarchar(1000)
    , regioncode nvarchar(2)
    , isHouse bit
)

create table #ParsedTmp
(
    houseguid uniqueidentifier
    , aoguid uniqueidentifier
    , postalcode nvarchar(6)
    , address nvarchar(1000)
    , regioncode nvarchar(2)
    , isHouse bit
)

/
declare @pack int = 24, @size int = 100000; 
;

declare
    @LastAddressId int = (select max(AddressId) from #toparse)
    , @CurrentAddressId int = (@pack - 1) * @size
    , @CurrentAddressStr nvarchar(1000)
;

while @CurrentAddressId >= (@pack - 1) * @size and @CurrentAddressId < @pack * @size 
begin

    select top 1 @CurrentAddressId = AddressId
    from #toparse
    where AddressId > @CurrentAddressId
    order by AddressId
    ;
    
    select @CurrentAddressStr = Address
    from #toparse
    where AddressId = @CurrentAddressId
    ;
    
    insert #ParsedTmp
    exec fias.[dict].[spGetAddress] @CurrentAddressStr
    ;
    
    insert ParsedAddresses
    select @CurrentAddressId, *
    from #ParsedTmp
    ;
    
    truncate table #ParsedTmp
    ;
    
end
/
24756
2571121

fias.[dict].[spGetAddress] N'Иркутская обл, Иркутск г, Березовый мкр, д 101'
--98
--208
--535
--533
--482
--290
--480
--520
--421
--429
--459
--369
/

select distinct
    a.id
    , a.AddressStr
    , pa.Address
from client.Address a
cross apply
(
    select top 1 *
    from ParsedAddresses pa
    where pa.AddressId = a.id
    order by len(pa.Address)
) pa
where exists 
    (
        select 1 from ParsedAddresses pa2
        where pa2.AddressId = a.id
    )
/
select *
from ParsedAddresses pa
where not exists 
    (
        select 1 from ParsedAddresses pa2
        where pa2.AddressId = pa.AddressId
    )
/
select *
from client.vw_address
where AddressId = 343886
/
with a as 
(
    select distinct
        va.AddressId
        , replace(a.AddressStr, h.house, '') as Address
        , va.City
        , max(case 
                when spl.value like N'% обл' 
                    or spl.value like N'% респ' 
                    or spl.value like N'% край' 
                    or spl.value like N'респ %'
                     or spl.value like N'% АО'
                     or spl.value like N'% Югра'
                then spl.value end) as Region
    from client.Address a
    inner join #alm tp on tp.AddressId = a.id
    inner join client.vw_address va on va.AddressId = a.id
    outer apply
    (
        select reverse(left( reverse(a.AddressStr), patindex(N'% д ,%', reverse(a.AddressStr)) + 3)) as house
    ) h
    outer apply
    (
        select 
            rtrim(ltrim(spl.value)) as value
            , row_number() over (partition by a.AddressStr order by a.AddressStr) as Num
        from string_split(replace(a.AddressStr, h.house, ''), ',') spl
    ) spl
    where a.AddressStr != ''
    group by replace(a.AddressStr, h.house, ''), reverse(left( reverse(a.AddressStr), patindex(N'% д ,%', reverse(a.AddressStr)) + 1))
        , va.AddressId, va.City
)

,a2 as 
(
    select
        a.AddressId
        , replace(a.Address, isnull(Region + ', ', ''), '') as Address
        , a.City
        , spl.*
        , row_number() over (partition by a.addressid order by spl.NUm desc) as ReversedNum
    from a
    outer apply
    (
        select 
            rtrim(ltrim(spl.value)) as value
            , row_number() over (partition by replace(a.Address, isnull(Region, ''), '') order by a.Address) as Num
        from string_split(replace(a.Address, isnull(Region + ', ', ''), ''), ',') spl
    ) spl
)

,a3 as 
(
    select
        a2.addressid
        , a2.address
        , ltrim(rtrim(replace(a2.Address, ', ' + max(case when a2.ReversedNum = 1 then value end), ''))) as City
        , ltrim(rtrim(max(case when a2.ReversedNum = 1 then value end))) as Street
    from a2
    group by a2.addressid, a2.address, a2.city
)

--select
--    a3.*
--    ,json_modify(json_modify(json_modify(json_modify(json_modify(a.Data
--        , '$.data.city_with_type', a3.City)
--        , '$.data.street_with_type', a3.Street)
--        , '$.data.region_with_type', N'Неизвестно')
--        , '$.data.region_kladr_id', N'00') 
--        , '$.data.settlement_with_type', null)
--        as Data
--    , a.RegionId
--update a set Data = json_modify(json_modify(json_modify(json_modify(json_modify(a.Data
        , '$.data.city_with_type', a3.City)
        , '$.data.street_with_type', a3.Street)
        , '$.data.region_with_type', N'Неизвестно')
        , '$.data.region_kladr_id', N'00') 
        , '$.data.settlement_with_type', null)
from a3
inner join client.Address a on a.id = a3.AddressId
--where addressid = 557068
--order by len(street) desc

/
drop table if exists #oth
;

select
    a.id
    ,a.LocationId
    ,a.data
into #oth
from "BOR-BOR-DB-LIME-2".Borneo.client.address a
where Data is not null

create index IX_oth_LocationId on #oth(LocationId)
/
declare @pack int = 13, @size int = 200000; 

update top (@size) a set ModifiedBy = 0x44, Data =
--    select top (@size)
--        a.id 
--        ,a.clientid
--    ,
    replace(replace(replace(replace((
        select
            replace((
                select 
                    d.Region as region_with_type
                    , d.Area as area_with_type
                    , d.City as city_with_type
                    , d.Settlement as settlement_with_type
                    , d.Street as street_with_type
                    , coalesce(a.PostCode, ha.postalcode, r.postalcode, d.PostalCode, '600000') as postal_code
                    , isnull(ha.housenum, reverse(substring(reverse(a.AddressStr), 1, charindex(',', reverse(a.AddressStr)) - 2))) as house
                    , coalesce(ha.buildnum + ' ' + ha.strucnum, ha.buildnum, ha.strucnum) as block
                    , d.OKATO as okato
                    , d.OKTMO as oktmo
                    , d.RegionKLADR as region_kladr_id
                from (select 1) b(v)
                for json auto, without_array_wrapper
            ), '\"', '`') as data
            , replace(a.AddressStr, '"', '`') as unrestricted_value
        from (select 1) b(v)
        for json auto, without_array_wrapper
    ), '"{', '{'), '}"', '}'), '\"', '"'), '`', '\"')-- as Data
from client.Address a
left join fias.dict.hierarchy r on r.regioncode = cast(a.RegionId as nvarchar(3)) 
    and r.aolevel = 1
left join fias.dict.houseactive ha on ha.houseguid = a.BuildingId
--outer apply
--(
--    select top 1
--        a2.id
--        ,a2.Data
--    from client.Address a2
--    where a2.LocationId = a.LocationId
--        and a2.id != 538
--    order by a2.id desc
--) a2
outer apply
(
    select top 1
        a2.Data
    from #oth a2
    where a2.LocationId = a.LocationId
) a2
outer apply openjson(a2.Data)
with
(
    Region nvarchar(100) '$.data.region_with_type'
    , Area nvarchar(100) '$.data.area_with_type'
    , City nvarchar(100) '$.data.city_with_type'
    , Settlement nvarchar(100) '$.data.settlement_with_type'
    , Street nvarchar(100) '$.data.street_with_type'
    , PostalCode nvarchar(100) '$.data.postal_code'
    , House nvarchar(100) '$.data.house'
    , HouseType nvarchar(100) '$.data.house_type'
    , Block nvarchar(100)'$.data.block'
    , BlockType nvarchar(100)'$.data.block_type'
    , OKATO nvarchar(100) '$.data.okato'
    , OKTMO nvarchar(100) '$.data.oktmo'
    , RegionKLADR nvarchar(50) '$.data.region_kladr_id'
) d
where a2.Data is not null
    and a.Data is null
    and a.AddressStr != ''
    and a.id >= (@pack - 1) * @size
    and a.id < @pack * @size
;

declare 
    @packsleft int = (select (max(id) - @pack * @size) * 1.0 / @size from client.Address a where data is null)
    ,@PctEmpty numeric(5, 2) = (select 1 - count(data) * 1.0 / count(*) as PctEmpty from client.Address a)
;

print 'pack: ' + format(@pack, '#,#0')
print '@PctEmpty: ' + format(@PctEmpty, '#,#0.##%')
print '@packsleft: ' + format(@packsleft, '#,#0')
/

drop table if exists #oth
;

select
    a.id
    ,a.LocationId
    ,a.data
into #oth
from "BOR-DB-LIME-2".Borneo.client.address a
where Data is not null

create index IX_oth_LocationId on #oth(LocationId)
/

select count(*)
from dbo.DadataMangoProcessed
order by id
/

create index IX_dbo_DadataMango_address on DadataMango("Address (стало)")
select top 100 *
from DadataMangoProcessed
/
declare @pack int = 13, @size int = 200000; 
;

select top 100 
    a.id
    ,concat('{"data":' + (
        select 
             concat("Район", ' ', "Тип района") as area_with_type
             , nullif(concat("Тип дома", ' ', "Дом"), ' ') as house
             , "Код ОКАТО" as okato
             , "Код ОКТМО" as oktmo
             , a.PostCode as postal_code
             , "Код КЛАДР" as region_kladr_id
             , nullif(concat("Регион", ' ', "Тип региона"), ' ') as region_with_type
             , nullif(concat("Город", ' ', "Тип города"), ' ') as city_with_type
             , nullif(concat("Улица", ' ', "Тип улицы"), ' ') as street_with_type
             , nullif(concat("Тип н/п", ' ', "Н/п"), ' ') as settlement_with_type
        from (select 1) b(c)
        for json auto, without_array_wrapper
    ), ',"unrestricted_value":"', a.AddressStr, '"}')
from client.Address a
inner join dbo.DadataMango mp on mp."Address (стало)" = a.AddressStr
where a.Data is null
--    and a.id >= (@pack - 1) * @size
--    and a.id < @pack * @size
