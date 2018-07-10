select 
    dt.Template
    ,count(distinct comm.id) as TotalMessages
    ,count(distinct comm.ClientId) as UniqueClients
    ,count(distinct th.ClientId) as TariffAssigned
    ,count(distinct p.ClientId) as CreditTaken
from Ecc.SmsCommunication comm 
inner join Doc.CommunicationTemplate dt on dt.Uuid = comm.TemplateUuid
inner join Doc.CommunicationTemplateMetadata ctm on ctm.Id = dt.MetadataId
inner join Ecc.EnumEmailType et on et.Id = ctm.CommunicationType
left join client.vw_TariffHistory th on th.ClientId = comm.ClientId
    and cast(th.CreatedOn as date) >= cast(comm.CreatedOn as date)
    and th.CreatedOn >= '20180702'
left join prd.vw_product p on p.ClientId = comm.ClientId
    and p.Status >= 2
    and p.CreatedOn >= '20180702'
    and cast(p.CreatedOn as date) >= cast(comm.CreatedOn as date)
where ctm.TemplateType in (1, 10)
    and et.Id in (115,116,117, 8, 9)
group by dt.Template