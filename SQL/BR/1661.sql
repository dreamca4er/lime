with np as 
(
    select
        p.Productid
        ,p.ContractNumber
        ,p.StartedOn
        ,p.PaymentWayName
        ,p.Amount as Amount
        ,p.Period
        ,cast(sum(a.SaldoNt) * -1 as nvarchar(10)) as CurrentDebt
        ,c.clientid
        ,c.DateRegistered
        ,c.Email
        ,c.IpAddress
        ,c.PhoneNumber
        ,cc.NumberMasked
        ,c.Passport
        ,c.IssuedOn
        ,c.IssuedBy
        ,c.INN
    from #tmp t
    inner join prd.vw_Product p on t.ClientId = p.ClientId
    inner join client.vw_Client c on c.clientid = p.ClientId
    inner join acc.vw_acc a on a.ProductId = p.ProductId
        and left(a.Number, 5) in ('48801', '48802', '48803', N'Штраф')
    inner join pmt.Payment pay on pay.ContractNumber = p.ContractNumber
        and pay.PaymentDirection = 1
    inner join pmt.CreditCardPaymentInfo ccpi on ccpi.PaymentId = pay.id
    inner join client.CreditCard cc on cc.Id = ccpi.CreditCardId 
    where p.status > 2
    group by 
        p.Productid
        ,p.ContractNumber
        ,p.StartedOn
        ,p.PaymentWayName
        ,p.Amount
        ,p.Period
        ,c.Email
        ,c.IpAddress
        ,c.PhoneNumber
        ,cc.NumberMasked
        ,c.DateRegistered
        ,c.Passport
        ,c.IssuedOn
        ,c.IssuedBy
        ,c.INN
        ,c.clientid
)
select *
from np

union

SELECT 
    264391 AS ProductId
    ,'1283369001' AS ContractNumber
    ,'2017-09-19 00:00:00.0' AS StartedOn
    ,N'Карта' AS column4
    ,2500 AS Amount
    ,14 AS Period
    ,N'Кредит продан по цессии' AS CurrentDebt
    ,1283369 AS clientid
    ,'2017-09-16 11:54:07.59' AS DateRegistred
    ,'Larisa206@free-org.com' AS EmailAddress
    ,'77.222.96.123' AS IpAddress
    ,'79822783130' AS PhoneNumber
    ,'533157******6551' AS NumberMasked
    ,'7512035789' AS Passport
    ,'2012-07-17 00:00:00.0' AS IssuedOn
    ,N'ОУФМС РОССИИ ПО ЧЕЛЯБИНСКОЙ ОБЛ. В КУСИНСКОМ Р-НЕ' AS IssuedBy
    ,null AS INN