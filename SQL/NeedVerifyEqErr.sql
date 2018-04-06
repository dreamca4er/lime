drop table if exists #c
;

select
    a.*
    ,eq.RequestXml
    ,eq.ResponseXml
into #c
from client.Client c
inner join client.Address a on a.ClientId = c.id
    and a.AddressType = 1
cross apply
(
    select top 1 ResponseXml, RequestXml
    from cr.EquifaxRequest eq
    where eq.ClientId = c.id
    order by eq.id desc
) eq
where Substatus in (201, 203)
    and AdminProcessingFlag = 1
;

select
    ClientId
    ,addressstr
    ,placementid
    ,locationid
    ,RequestXml
from #c
where ResponseXml like '%<responsecode>12</responsecode>%'
order by placementid

/*
1855878
1330445
*/