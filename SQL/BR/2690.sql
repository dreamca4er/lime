select
    p.id
    ,p.PaymentStatus
    ,p.ProcessedOn
    ,fpi.* -- update p set p.PaymentStatus = 2
from pmt.Payment p 
inner join pmt.CreditCardPaymentInfo ccpi on ccpi.PaymentId = p.id
inner join pmt.FondyPaymentInfo fpi on fpi.CreditCardPaymentInfoId = ccpi.Id
where p.ContractNumber = '1900110041'
    and p.PaymentDirection = 2
    and fpi.ResponseStatus = 0 
    
select *
from prd.Product
where ContractNumber = '1900110041'

select * -- delete
from prd.OperationLog 
where ProductId = 433751
    and cast(OperationDate as date) = '20180804'
    and id = 21857842

select
    p.id
    ,qpi.*
from pmt.Payment p
inner join pmt.QiwiPaymentInfo qpi on qpi.PaymentId = p.id
where "Order" in
    (
        select
            "Order"
        from pmt.Payment
        where PaymentStatus = 5
            and CreatedOn >= '20180801'
        group by "Order"
        having count(*) > 1
    )