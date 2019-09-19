select d.id, ct.Description, d.name, d.Template
-- update d set IsActive = 0
from doc.CommunicationTemplate d
inner join doc.CommunicationTemplateMetadata m on m.id = d.MetadataId
inner join doc.EnumCommunicationTemplateType ct on ct.Id = m.TemplateType
where d.IsActive = 1
--    and ct.Description like N'%смс%'
--where 1=1
   and (d.Uuid = '03A6AA70-BB41-46DD-929B-34F7B8060ACD'
       or d.Name like N'В день ПРОСРОЧКИ%'
       )
