select
    c.clientId
    ,c.fio
    ,c.PhoneNumber
    ,c.inn
from client.vw_Client c
where len(inn) < 12