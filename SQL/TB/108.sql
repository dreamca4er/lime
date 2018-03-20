select
    c.clientid
    ,c.fio
    ,c.Email
    ,c.PhoneNumber
from client.vw_client c
where c.IsFrauder = 0
    and c.IsDead = 0
    and c.IsCourtOrdered = 0
    and c.Status not in (3, 4)
    and not exists
                (
                    select 1 from prd.vw_product p
                    where p.clientId = c.clientid
                        and p.status not in (1, 5)
                )
