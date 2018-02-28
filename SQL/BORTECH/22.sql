select
    c.id as clientid
    ,concat(c.LastName, ' ', c.FirstName, ' ', c.FatherName) as fio
    ,p.PhoneNumber
    ,c.Email
from client.Client c
left join client.Phone p on p.ClientId = c.id
    and p.IsMain = 1
where Substatus in (102, 201, 202, 203, 204)
    and IsFrauder = 0
    and IsDead = 0
    and IsCourtOrdered = 0
    and exists 
            (
                select 1 from prd.vw_product p
                where p.clientId = c.Id
                    and productType = 1
                    and p.status not in (0, 1)
            )
