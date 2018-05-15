select
    p.productid
    ,p.clientId
    ,p.Amount
    ,cct.Description as CreditCardType
    ,(select max(v) from (values(p.Amount * 0.006), (33)) as t(v)) as var1
    ,case 
        when cc.CreditCardType = 1 
        then p.Amount * 0.0055 + 12 
        else p.Amount * 0.0055 + 6
    end as var2
from prd.vw_Product p 
inner join pmt.Payment pay on pay.ContractNumber = p.ContractNumber
    and pay.PaymentDirection = 1
inner join pmt.CreditCardPaymentInfo ccpi on ccpi.PaymentId = pay.id
inner join client.CreditCard cc on cc.Id = ccpi.CreditCardId
inner join client.EnumCreditCardType cct on cct.Id = cc.CreditCardType
where p.status > 2
    and p.StartedOn >= '20180101'
    and p.PaymentWay = 1
