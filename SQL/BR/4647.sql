select
    c.clientid
    ,c.fio
    ,c.substatusName
    ,c.IsFrauder
    ,a.RegionId as RegionCode 
    ,h.name as RegionName
    ,p.*
from client.vw_client c
left join client.Address a on a.ClientId = c.clientid
    and a.AddressType = 1
left join fias.dict.hierarchy h on h.regioncode = a.RegionId
    and h.aolevel = 1
cross apply
(
    select
        p.Productid
        ,p.Amount
        ,p.StatusName
    from prd.vw_product p
    where p.StartedOn >= '20180101'
        and p.PaymentWay = 4
        and not exists 
            (
                select 1 from client.CreditCard cc
                where cc.CreatedOn < p.CreatedOn
                    and cc.ClientId = p.ClientId
            )
        and p.ClientId = c.clientid
) p
order by c.clientid, p.Productid