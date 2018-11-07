select
    sc.TemplateUuid
    ,spi.SenderTitle
    ,ct.Name
    ,count(*) as SMSCnt
    ,min(sc.CreatedOn) as FirstSMSDate
from ecc.SmsCommunication sc
inner join ecc.SmsProviderInteraction spi on spi.Id = sc.SmsProviderInteractionId
inner join doc.CommunicationTemplate ct on ct.Uuid = sc.TemplateUuid
where sc.CreatedOn >= '20181001'
    and sc.TemplateUuid in
    (
        select
            sc.TemplateUuid
        from ecc.SmsCommunication sc
        inner join ecc.SmsProviderInteraction spi on spi.Id = sc.SmsProviderInteractionId
        where sc.CreatedOn >= '20181001'
        group by sc.TemplateUuid
        having count(distinct spi.SenderTitle) > 1
    )
group by 
    sc.TemplateUuid
    ,spi.SenderTitle
    ,ct.Name
/
select
    ec.TemplateUuid
    ,ct.Name
    ,ec.ProviderName
    ,count(*) as EmailCount
    ,min(ec.CreatedOn) as FirstEmailDate
    ,max(ec.CreatedOn) as LastEmailDate
from ecc.EmailCommunication ec
inner join doc.CommunicationTemplate ct on ct.Uuid = ec.TemplateUuid
where TemplateUuid in
    (
        select
            TemplateUuid
        from ecc.EmailCommunication
        where CreatedOn >= '20181001'
        group by
             TemplateUuid
        having count(distinct ProviderName) > 1
    )
    and ec.CreatedOn >= '20181001'
group by
    ec.TemplateUuid
    ,ct.Name
    ,ec.ProviderName

/

select
    ct.Id as TemplateId
    ,ct.Name as TemplateName
    ,ec.ProviderName
    ,c.id as ClientId
    ,concat(c.LastName, ' ', c.FirstName, ' ', c.FatherName) as fio
    ,ec.CreatedOn
from ecc.EmailCommunication ec
inner join client.Client c on c.id = ec.ClientId
inner join doc.CommunicationTemplate ct on ct.Uuid = ec.TemplateUuid
where TemplateUuid in
    (
        select
            TemplateUuid
        from ecc.EmailCommunication
        where CreatedOn >= '20181001'
        group by
             TemplateUuid
        having count(distinct ProviderName) > 1
    )
    and ec.CreatedOn >= '20181001'
/

