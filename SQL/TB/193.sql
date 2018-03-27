select
    c.clientid
    ,c.LastName
    ,c.FirstName
    ,c.FatherName
    ,c.Email
    ,c.PhoneNumber
from client.vw_client c
where c.status not in (3, 4)
    and c.IsFrauder = 0
    and c.IsDead = 0
    and not exists 
                (
                    select 1 from prd.vw_Product p
                    where p.status not in (1, 5) 
                        and p.clientId = c.clientid
                )