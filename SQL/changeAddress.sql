exec fias.dict.spgetaddress N'ЕКАТЕРИНБУРГ Г, СВЕТЛЫЙ ПЕР, Д.3', '0697B011-731C-45C3-847F-D4319F59004D'
with n as 
(
    select
        ha.houseguid as BuildingId
        ,ha.aoguid as LocationId
        ,ha.postalcode as PostCode
        ,ha.address as AddressStr
        ,ha.regioncode as RegionId
        ,'383' as apartment
        ,hp.aoguid as PlacementId
        ,hp.name as Placement
    from fias.dict.houseactive ha
    inner join fias.dict.hierarchy h on h.aoguid = ha.aoguid
    inner join fias.dict.hierarchy hp on hp.aoguid = h.placementGuid
    where ha.houseguid = '22AE4B51-9C48-45D4-AFC8-BF6EA7D928DE'
)

update a
set
    a.BuildingId = n.BuildingId
    ,a.LocationId = n.LocationId
    ,a.PostCode = n.PostCode
    ,a.AddressStr = n.AddressStr
    ,a.RegionId = n.RegionId
    ,a.apartment = n.apartment
    ,a.PlacementId = n.PlacementId
    ,a.Placement = n.Placement
from client.address a, n
where a.clientid = 1774203
    and a.AddressType = 1

select *
from client.address
where clientid = 1774203
    and AddressType = 1
