select
    p.clientId
    ,c.fio
    ,c.PhoneNumber
    ,c.Email
from prd.vw_product p
inner join client.vw_client c on c.clientid = p.clientId
where p.productType = 1
    and p.status in (3, 4, 7)
    and p.StartedOn < '20180225'
    and not exists 
                (
                    select 1 from acc.vw_prodDebt pd
                    where pd.productid = p.productid
                        and pd.debtAmnt + pd.debtFine + pd.debtComission = 0
                )
