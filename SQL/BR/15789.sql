--drop table if exists #CanceledBA
;

select
    p.Productid
    , p.ClientId
    , c.fio
    , c.PhoneNumber
    , iif(c.EmailConfirmed = 1, c.Email, null) as Email
    , ma.MaxAmount
--into #CanceledBA
from prd.vw_product p
inner join client.vw_client c on c.clientid = p.ClientId
outer apply
(
    select top 1 th.MaxAmount
    from client.vw_TariffHistory th
    where th.ClientId = p.ClientId
        and th.IsLatest = 1
    order by th.MaxAmount desc
) ma
where p.Status = 2
    and p.PaymentWay = 2
;

select *
from #CanceledBA ba
where exists
    (
        select 1 from prd.vw_product p
        where p.Productid = ba.Productid
            and p.Status = 2
            and p.PaymentWay = 2
    )
