with fcb as 
(
    SELECT 60130 AS id,1188 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 68708 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 68715 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 80626 AS id,1209 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 81653 AS id,1184 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 86514 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 89703 AS id,1184 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 102054 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 107277 AS id,1188 AS IsFraudChangedByUserId
)

select
    c.clientid
    ,c.fio
    ,c.IsFrauderChangedAt
    ,un.ClaimValue as IsFrauderChangedBy 
    ,h.name as RegionName
    ,p.Productid
    ,p.StartedOn
    ,p.Amount
    ,p.StatusName
    ,bapi.AccountNum
    ,b.Name as BankName
from client.vw_client c
inner join prd.vw_product p on p.ClientId = c.clientid
    and p.PaymentWay = 2
inner join pmt.Payment pay on pay.ContractNumber = p.ContractNumber
    and pay.PaymentDirection = 1
inner join pmt.BankAccountPaymentInfo bapi on bapi.PaymentId = pay.Id
inner join client.BankAccount ba on ba.Id = bapi.BankAccountId
inner join client.Bank b on b.id = ba.BankId
left join fcb on fcb.id = p.Productid 
left join client.Address a on a.ClientId = c.clientid
    and a.AddressType = 1
left join fias.dict.hierarchy h on h.regioncode = a.RegionId
    and h.aolevel = 1
left join sts.OldUsers ou on ou.AdminId = fcb.IsFraudChangedByUserId
left join sts.users u on u.UserName = ou.LoginName
left join sts.UserClaims un on un.UserId = u.id
    and un.ClaimType = 'name'
where c.IsFrauder = 1
    and c.IsFrauderChangedAt >= '20180101'
    and p.Status >= 2
/
with fcb as 
(
    SELECT 35461 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 47577 AS id,1201 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 47795 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 48098 AS id,1347 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 59006 AS id,1201 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 62029 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 64774 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 68742 AS id,1201 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 68978 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 68994 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 69478 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 71188 AS id,1407 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 71406 AS id,1188 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 74717 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 75149 AS id,1184 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 75614 AS id,1304 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 78711 AS id,1184 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 79936 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 86331 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 97876 AS id,1188 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 99117 AS id,1229 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 99254 AS id,1177 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 99471 AS id,1203 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 103551 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 115012 AS id,1220 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 120676 AS id,1220 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 124392 AS id,1220 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 122568 AS id,1347 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 114052 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 105967 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 97123 AS id,1312 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 96877 AS id,1229 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 96428 AS id,1229 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 92277 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 84999 AS id,1188 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 79391 AS id,1317 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 68343 AS id,1317 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 66893 AS id,1317 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 57704 AS id,1331 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 57337 AS id,1331 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 146788 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 143741 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 137227 AS id,null AS IsFraudChangedByUserId
    UNION ALL
    SELECT 81994 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 34815 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 83498 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 87203 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 91787 AS id,1214 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 92346 AS id,1281 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 95801 AS id,1281 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 98635 AS id,1188 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 107293 AS id,1449 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 110534 AS id,1457 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 104067 AS id,1213 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 93460 AS id,1386 AS IsFraudChangedByUserId
    UNION ALL
    SELECT 86350 AS id,1209 AS IsFraudChangedByUserId
)

select
    c.clientid
    ,c.fio
    ,c.IsFrauderChangedAt
    ,un.ClaimValue as IsFrauderChangedBy 
    ,h.name as RegionName
    ,p.Productid
    ,p.StartedOn
    ,p.Amount
    ,p.StatusName
    ,cc.NumberMasked
from client.vw_client c
inner join prd.vw_product p on p.ClientId = c.clientid
    and p.PaymentWay = 1
inner join pmt.Payment pay on pay.ContractNumber = p.ContractNumber
    and pay.PaymentDirection = 1
inner join pmt.CreditCardPaymentInfo ccpi on ccpi.PaymentId = pay.id
inner join client.CreditCard cc on cc.id = ccpi.CreditCardId
left join fcb on fcb.id = p.Productid 
left join client.Address a on a.ClientId = c.clientid
    and a.AddressType = 1
left join fias.dict.hierarchy h on h.regioncode = a.RegionId
    and h.aolevel = 1
left join sts.OldUsers ou on ou.AdminId = fcb.IsFraudChangedByUserId
left join sts.users u on u.UserName = ou.LoginName
left join sts.UserClaims un on un.UserId = c.IsFrauderChangedBy--u.id
    and un.ClaimType = 'name'
where c.IsFrauder = 1
    and c.IsFrauderChangedAt >= '20180101'
    and p.Status >= 2
/

select top 1 *
from client.CreditCard cc
order by cc.id desc