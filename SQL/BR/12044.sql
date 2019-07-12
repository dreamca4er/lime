select
    pay.ProcessedOn as CurrentProcessedOn
    , p.ProcessedOn as NewProcessedOn
    , pay.ContractNumber
    , pr.id
    , ol.CommandSnapshot as CurrentSnapshot
    , json_modify(json_modify(ol.CommandSnapshot, '$.OperationDate', p.ProcessedOn), '$.SentOn', p.ProcessedOn) as NewSnapShot
-- update pay set pay.ProcessedOn = p.ProcessedOn
-- update ol set ol.CommandSnapshot = json_modify(json_modify(ol.CommandSnapshot, '$.OperationDate', p.ProcessedOn), '$.SentOn', p.ProcessedOn)
from 
(
    values
    ('5000065520', '2019-06-24 00:00:10.100')
    , ('5000065850', '2019-06-25 01:44:05.500')
    , ('5000065851', '2019-06-25 01:44:05.500')
    , ('5000065855', '2019-06-25 08:22:06.600')
) p(ContractNumber, ProcessedOn )
inner join pmt.Payment pay on pay.ContractNumber = p.ContractNumber
    and pay.PaymentStatus = 5
    and pay.Paymentdirection = 1
inner join prd.product pr on pr.ContractNumber = p.ContractNumber
left join prd.OperationLog ol on ol.productId = pr.id
    and ol.OperationFullName = 'Prd.Domain.Operations.ShortTermOperations.ShortTermCreditSendMoneyOperation'
    and json_value(ol.CommandSnapshot, '$.IsSuccess') = 'true'


/

select
    pay.ProcessedOn as CurrentProcessedOn
    , p.ProcessedOn as NewProcessedOn
    , pay.ContractNumber
    , pr.id
    , ol.CommandSnapshot as CurrentSnapshot
    , json_modify(json_modify(ol.CommandSnapshot, '$.OperationDate', p.ProcessedOn), '$.SentOn', p.ProcessedOn) as NewSnapShot
-- update pay set pay.ProcessedOn = p.ProcessedOn
-- update ol set ol.CommandSnapshot = json_modify(json_modify(ol.CommandSnapshot, '$.OperationDate', p.ProcessedOn), '$.SentOn', p.ProcessedOn)
from 
(
    values
    (61496068, '2019-06-27 00:02:08.800')
    , (61535775, '2019-06-30 00:00:11.110')
    , (61543589, '2019-07-01 08:40:09.000')
) p(id, ProcessedOn )
inner join pmt.Payment pay on pay.id = p.id
    and pay.PaymentStatus = 5
    and pay.Paymentdirection = 1
inner join prd.product pr on pr.ContractNumber = pay.ContractNumber
left join prd.OperationLog ol on ol.productId = pr.id
    and ol.OperationFullName = 'Prd.Domain.Operations.ShortTermOperations.ShortTermCreditSendMoneyOperation'
    and json_value(ol.CommandSnapshot, '$.IsSuccess') = 'true'