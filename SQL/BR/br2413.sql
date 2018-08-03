/*
drop table if exists #p
;

select
    p.ContractNumber
    ,p.Productid
    ,p.ClientId
    ,cast(replace(cppi.RequestXml, 'actionName=FINDPAY&dealerTransactionId=', '') as nvarchar(100)) as TransactionID
    ,cppi.id as CreditPilotPaymentInfoId
    ,cppi.CreditCardPaymentInfoId
    ,pay.id as PaymentId
    ,p.StartedOn
    ,p.CreatedOn
    ,p.Amount
    ,p.StatusName
    ,pay."Order" as OrderId
into #p
from prd.vw_product p
inner join pmt.Payment pay on pay.ContractNumber = p.ContractNumber
    and pay.PaymentDirection = 1
inner join pmt.CreditCardPaymentInfo ccpi on ccpi.PaymentId = pay.id
inner join pmt.CreditPilotPaymentInfo cppi on cppi.CreditCardPaymentInfoId = ccpi.Id
    and cppi.ResultCode = 1
where p.PaymentWay = 1
    and p.StartedOn >= '20180701'
    and p.StartedOn < '20180801'
    and p.Status > 2
;

create index IX_p_TransactionID on #P (TransactionID)
*/


select
    d.TransactionID
    ,d.KPDAccount
    ,Datetime
    ,d.Account
    ,d.Amount
    ,d.Bounty
    ,d.OnlineComission
    ,cast(datetime as date) as date
from dbo.br2379 d
where not exists
    (
        select 1
        from #p
        where #p.TransactionID = d.TransactionID
    )
    
select
    #p.ClientId
    ,#p.Productid
    ,#p.ContractNumber
    ,#p.Amount
    ,#p.StatusName
    ,#p.PaymentId
    ,#p.OrderId
    ,cppi.id as CreditPilotPaymentInfoId
    ,cppi.CreatedOn
    ,cppi.ResultCode
    ,cppi.RequestXml
    ,cppi.ResponseXml
from #p
inner join  pmt.CreditPilotPaymentInfo cppi on #p.CreditCardPaymentInfoId = cppi.CreditCardPaymentInfoId
where #p.TransactionID in ('4180719145622012900','4180719184613012936','4180721133950013213','4180722185433013387','4180723164914013508')


select
    "Order"
    ,max(CreatedOn)
from pmt.Payment
where PaymentStatus = 5
group by "Order"
having count(*) > 1


select
    qpi.*
from pmt.Payment p
inner join pmt.QiwiPaymentInfo qpi on qpi.PaymentId = p.id
--inner join pmt.FondyPaymentInfo fpi on fpi.CreditCardPaymentInfoId = ccpi.id
where p."Order" = '3180802124501065696'