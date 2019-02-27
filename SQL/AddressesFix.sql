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
--declare @pack int = 13, @size int = 200000; 
--;
--
--select top 100
--    a.id
--    , a.ClientId
--    ,
update top (100000) a set Data = 
    concat('{"data":' + (
        select 
             nullif(concat("Район", ' ', "Тип района"), ' ') as area_with_type
             , nullif(concat("Тип дома", ' ', "Дом"), ' ') as house
             , "Код ОКАТО" as okato
             , "Код ОКТМО" as oktmo
             , a.PostCode as postal_code
             , "Код КЛАДР" as region_kladr_id
             , nullif(concat("Регион", ' ', "Тип региона"), ' ') as region_with_type
             , nullif(concat("Город", ' ', "Тип города"), ' ') as city_with_type
             , nullif(concat("Улица", ' ', "Тип улицы"), ' ') as street_with_type
             , nullif(concat("Тип н/п", ' ', "Н/п"), ' ') as settlement_with_type
             , nullif(concat("Тип корпуса/строения", ' ', "Корпус/строение"), ' ') as block
        from (select 1) b(c)
        for json auto, without_array_wrapper
    ), ',"unrestricted_value":"', a.AddressStr, '"}')
    , ModifiedOn = getdate()
    , ModifiedBy = 0x44
from client.Address a
inner join dbo.DadataMango mp on mp."Address (стало)" = a.AddressStr
where a.Data is null
--    and a.id >= (@pack - 1) * @size
--    and a.id < @pack * @size
;

select count(*)
from client.Address
where data is null
/

/

begin try
    select count(*)
    from client.vw_address 
    where Street = ''
end try

begin catch
    drop table if exists #a
    ;
    
    select 
        substring(e.er, patindex('%''%', e.er) + 1, 1) as c
        , cast(reverse(substring(reverse(e.er), 2, charindex(' ', reverse(e.er)) - 2)) as int) as p 
    into #a
    from (select ERROR_MESSAGE() as er) e
    
    declare
        @pos int = (select p from #a)
        , @let nvarchar(1) = (select c from #a)
        , @id int
    ;

    update a 
    set Data = replace(a.Data, 'unrestricted_value":"' + a.AddressStr + '"', 'unrestricted_value":"' + replace(AddressStr, '"', '\"') + '"')
        , @id = a.id
    from client.Address a
    where substring(data, @pos + 1, 1) = @let
        and substring(data, @pos, 1) = N'"'
        and AddressStr like '%"%'
    ;
    
    select *
    from client.vw_address
    where AddressId = @id
end catch  

/*
1519888
1356352
1356351
*/

 /
select *, replace(a.Data, 'unrestricted_value":"' + a.AddressStr + '"', 'unrestricted_value":"' + replace(AddressStr, '"', '\"') + '"')
-- update a set Data = replace(a.Data, 'unrestricted_value":"' + a.AddressStr + '"', 'unrestricted_value":"' + replace(AddressStr, '"', '\"') + '"')
from client.Address a
where AddressStr like '%"%'
    and Data like '%unrestricted_value":"' + a.AddressStr + '"%'
;
/
drop table if exists #a3
;

with a as 
(
    select distinct
        va.AddressId
        , a.ClientId
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
        , h.house
        , BuildingId
        , LocationId
        , RegionId
        , Postcode
        , AddressStr
    from client.Address a
    inner join client.vw_address va on va.AddressId = a.id
    outer apply
    (
        select reverse(left( reverse(a.AddressStr), charindex(N',', reverse(a.AddressStr)))) as house
    ) h
    outer apply
    (
        select 
            rtrim(ltrim(spl.value)) as value
            , row_number() over (partition by a.AddressStr order by a.AddressStr) as Num
        from string_split(replace(a.AddressStr, h.house, ''), ',') spl
    ) spl
    where a.AddressStr != ''
        and a.Data is null
    group by replace(a.AddressStr, h.house, ''), reverse(left( reverse(a.AddressStr), patindex(N'% д ,%', reverse(a.AddressStr)) + 1))
        , va.AddressId, va.City, a.ClientId, h.house
        , BuildingId
        , LocationId
        , RegionId
        , Postcode
        , AddressStr
)

,a2 as 
(
    select
        a.AddressId
        , replace(a.Address, isnull(Region + ', ', ''), '') as Address
        , a.City
        , spl.*
        , a.ClientId
        , row_number() over (partition by a.addressid order by spl.NUm desc) as ReversedNum
        , a.house
        , BuildingId
        , LocationId
        , RegionId
        , Postcode
        , AddressStr
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
        , a2.ClientId
        , a2.address
        , ltrim(rtrim(replace(a2.Address, ', ' + max(case when a2.ReversedNum = 1 then value end), ''))) as City
        , ltrim(rtrim(max(case when a2.ReversedNum = 1 then value end))) as Street
        , replace(a2.house, ', ', '') as house
        , BuildingId
        , LocationId
        , RegionId
        , Postcode
        , AddressStr
    from a2
    group by a2.addressid, a2.address, a2.city, a2.ClientId, a2.house
        , BuildingId
        , LocationId
        , RegionId
        , Postcode
        , AddressStr
)

select *
into #a3
from a3
;
create index IX_a on #a3(addressid) 
/

--select top 1
--    a.AddressId
update top (1000) adr set Data = concat('{"data":' + (
        select 
             null as area_with_type
             , a.house
             , '00' as okato
             , '00' as oktmo
             , a.PostCode as postal_code
             , right('00' + cast(a.RegionId as nvarchar(3)), 2)  as region_kladr_id
             , r.name as region_with_type
             , a.city as city_with_type
             , a.street as street_with_type
        from (select 1) b(c)
        for json auto, without_array_wrapper
    ), ',"unrestricted_value":"', replace(a.AddressStr, '"', '\"'), '"}')
    , ModifiedOn = getdate()
    , ModifiedBy = 0x44
from #a3 a
inner join client.Address adr on adr.id = a.Addressid
left join fias.dict.hierarchy r on  right('00' + r.regioncode, 2) = right('00' + cast(a.RegionId as nvarchar(3)), 2) 
    and r.aolevel = 1
where adr.Data is null
;

;
/

select *
into #va
from client.vw_address

create or alter view client.vw_GetAddress as 
select
    AddressId
    , ClientId
    , AddressType
    , PostalCode
    , isnull(nullif(left(OKATO, 2), ''), '45') as OkatoRegion
    , isnull(RegionCode, '77') as Region
    , isnull(Region, N'Москва г') as RegionName
    , isnull(City, N'Москва г') as City
    , isnull(Street, N'Профсоюзная ул') as Street
    , isnull(House, '1') as House
    , null as Building
    , Block 
from client.vw_address
/

select top 100 *
from client.vw_GetAddress