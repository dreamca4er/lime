select
    vc.clientid
    ,vc.fio
    ,vc.PhoneNumber
    ,vc.Email
from client.Client c
inner join client.vw_client vc on vc.clientid = c.id
where c.IsFrauder = 0
    and c.IsDead = 0
    and c.IsCourtOrdered = 0
    and isnull(c.UserBlockingPeriod, 0) = 0
    and not exists 
                (
                    select 1
                    from prd.vw_Product p
                    where c.Id = p.clientId
                        and p.status in (0, 2, 3, 4, 7)
                )
    and status = 1



