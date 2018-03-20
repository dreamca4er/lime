select
    vc.clientid
    ,concat(c.LastName, ' ', c.FirstName, ' ', c.FatherName) as fio
    ,vc.Email
    ,vc.PhoneNumber
    ,c.BirthDate
from client.Client c
inner join client.vw_client vc on vc.clientid = c.id
where datepart(mm, BirthDate) = 3
    and datepart(dd, BirthDate) between 19 and 25
    and isnull(c.IsFrauder, 0) = 0
    and isnull(c.IsDead, 0) = 0
    and c.Status != 3
    