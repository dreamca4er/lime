select
    c.clientid
    ,c.fio
    ,c.PhoneNumber
    ,c.Email
from prd.vw_product p
inner join client.vw_client c on c.clientid = p.clientId
outer apply
(
    select top 1
        dateadd(d, stp.Period, StartedOn) as WithProlong
    from prd.ShortTermProlongation stp
    where stp.ProductId = p.productid
        and stp.IsActive = 1
    order by stp.StartedOn desc
) stp
where p.status in (3, 4, 7)
    and isnull(WithProlong, dateadd(d, p.Period, p.StartedOn)) >= '20180225'
    and isnull(WithProlong, dateadd(d, p.Period, p.StartedOn)) < '20180302'

union

select
    c.clientid
    ,c.fio
    ,c.PhoneNumber
    ,c.Email
from prd.vw_statusLog sl
inner join prd.vw_product p on p.productid = sl.ProductId
inner join client.vw_client c on c.clientid = p.clientId
where sl.status = 5
    and sl.startedon >= '20180225'
    and sl.startedon < '20180302'

/

select
    c.clientid
    ,c.fio
    ,c.PhoneNumber
    ,c.Email
from prd.vw_product p
inner join client.vw_client c on c.clientid = p.clientId
where p.status in (3, 4, 7)
    and p.StartedOn < '20180225'
/

select
    c.clientid
    ,c.fio
    ,c.PhoneNumber
    ,c.Email
from prd.vw_product p
inner join client.vw_client c on c.clientid = p.clientId
where p.status in (3, 7)
    and p.productType = 1
    and p.StartedOn < '20180225'