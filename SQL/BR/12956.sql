select
    c.clientid
    , c.fio
    , c.PhoneNumber
    , p.Productid
    , p.ContractNumber
    , th.MaxAmount
    , p.StatusName
from prd.vw_product p
inner join client.vw_client c on c.clientid = p.ClientId
inner join pmt.Payment pay on pay.ContractNumber = p.ContractNumber
outer apply
(
    select max(th.MaxAmount) as MaxAmount
    from client.vw_TariffHistory th
    where th.ClientId = p.ClientId
        and th.IsLatest = 1
) th
where 1=1 
    and p.PaymentWay = 2
--    and p.Status = 2
    and p.Productid in (410271,410302,410324,410325,410329,410343,410352,410353,410359,410364,410374,410378,411390,411393,411395,411402,412401,412403,412405,412409,412411,412412,412414,412415,412416,412420,412425,412426,412547)