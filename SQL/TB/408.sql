select
    c.id
    ,c.Timezone
    ,rt.Timezone as RealTimezone -- update c set c.Timezone = rt.Timezone
from client.Client c
inner join client.Address a1 on a1.ClientId = c.Id
    and a1.AddressType = 1
left join client.Address a2 on a2.ClientId = c.Id
    and a2.AddressType = 2
    and c.RegAddressIsFact = 0
inner join client.RegionTimezone rt on rt.RegionCode = isnull(cast(a2.RegionId as int),cast(a1.RegionId as int))
where c.Timezone != rt.Timezone
