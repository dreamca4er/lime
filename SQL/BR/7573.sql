delete from doc.CommunicationTemplateMetadata
;
set identity_insert doc.CommunicationTemplateMetadata ON
;
insert doc.CommunicationTemplateMetadata
(
    Id,CommunicationType,ReferenceId,CreatedOn,CreatedBy,TemplateType,AnyTimeAvailable,AccountedInteraction,AllowedFromHours,AllowedToHours,ProductIdentityType,PayDayOffset
)
select
    Id
    , CommunicationType
    , ReferenceId
    , CreatedOn
    , CreatedBy
    , TemplateType
    , AnyTimeAvailable
    , AccountedInteraction
    , AllowedFromHours
    , AllowedToHours
    , ProductIdentityType
    , PayDayOffset
from "BOR-DB-LIME-2".Borneo.doc.CommunicationTemplateMetadata
where id != 1803
;
set identity_insert doc.CommunicationTemplateMetadata OFF
;

delete from doc.CommunicationTemplate
;
set identity_insert doc.CommunicationTemplate ON
;
insert doc.CommunicationTemplate
(
    Id,Template,Version,CreatedOn,CreatedBy,MetadataId,Name,Uuid,IsActive
)
select
    ctl.Id
    , isnull(ctk.Template, ctl.Template) as Template
    , ctl.Version
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , ctl.MetadataId
    , isnull(ctk.Name, ctl.Name) as Name
    , ctl.Uuid
    , isnull(ctk.IsActive, ctl.IsActive) as IsActive
from "BOR-DB-LIME-2".Borneo.doc.CommunicationTemplate ctl
left join PROD_Admin.dbo.CommunicationTemplates ctk on ctk.id = ctl.id
where ctl.metadataid != 1803
;
set identity_insert doc.CommunicationTemplate OFF
;