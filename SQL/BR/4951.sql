select ct.id, ct.Name -- update ct set IsActive = 0
from Doc.CommunicationTemplate ct
inner join Doc.CommunicationTemplateMetadata ctm on ctm.Id = ct.MetadataId
inner join doc.EnumCommunicationTemplateType ctt on ctt.Id = ctm.TemplateType
outer apply
(
    select top 1 spi.SenderTitle
    from ecc.SmsCommunication sc
    inner join ecc.SmsProviderInteraction spi on spi.Id = sc.SmsProviderInteractionId
    where sc.TemplateUuid = ct.Uuid
        and sc.CreatedOn >= '20181110'
) sc
where ctt.Name like '%sms%'
    and ct.IsActive = 1
    and sc.SenderTitle = 'OOO SKG'