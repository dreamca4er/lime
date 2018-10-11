select cppi.*
from pmt.Payment p
inner join pmt.CreditCardPaymentInfo ccpi on ccpi.PaymentId = p.id
inner join pmt.CreditPilotPaymentInfo cppi on cppi.CreditCardPaymentInfoId = ccpi.Id
where p.id = 2002029
    

select fpi.*
from pmt.Payment p
inner join pmt.CreditCardPaymentInfo ccpi on ccpi.PaymentId = p.id
inner join pmt.FondyPaymentInfo fpi on fpi.CreditCardPaymentInfoId = ccpi.Id
where p.PaymentDirection = 2
    and p.id in (1331261, 1331303)
    

select cpi.*
from pmt.Payment p
inner join pmt.ContactPayment cp on cp.PaymentId = p.Id
inner join pmt.ContactPaymentInfo cpi on cpi.ContactPaymentId = cp.id
where p.id = 1247031
