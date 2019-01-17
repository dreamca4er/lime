select
    c.clientid
    , c.LastName
    , c.FirstName
    , c.FatherName
    , c.Email
    , c.PhoneNumber
    , lc.LastCredRepaid
from client.vw_Client c
outer apply
(
    select max(DatePaid) as LastCredRepaid
    from prd.vw_AllProducts ap
    where ap.ClientId = c.clientid
) lc
where not exists 
    (
        select 1 from prd.vw_Product p
        where p.ClientId = c.clientid
            and p.Status not in (1, 5)
    )
    and not exists 
    (
        select 1 from client.vw_TariffHistory th
        where th.ClientId = c.clientid
            and th.IsLatest = 1
    )
    and c.Substatus = 202
    and c.DateRegistered >= '20180101'
    and c.EmailConfirmed = 1
    and lc.LastCredRepaid is not null