select
    c.clientid
    ,c.fio
    ,c.Email
    ,c.PhoneNumber
    ,p.productid
    ,p.PaymentWayName
    ,p.StartedOn
    ,p.statusName
    ,p.Amount
from prd.vw_product p
inner join client.vw_client c on c.clientid = p.clientId
where cast(p.StartedOn as date) between '20180320' and '20180323'