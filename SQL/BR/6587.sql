select
    spi.SenderTitle
    , dateadd(month, datediff(month, 0, sms.CreatedOn), 0) as Mnth
    , count(*) as smsCount
from ecc.SmsCommunication sms
inner join ecc.SmsProviderInteraction spi on spi.Id = sms.SmsProviderInteractionId
where DeliveryStatus in (2, 3, 4)
    and sms.CreatedOn >= '20180601'
group by 
    spi.SenderTitle
    , dateadd(month, datediff(month, 0, sms.CreatedOn), 0)