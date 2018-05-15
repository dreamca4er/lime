select
    c.clientid
    ,c.fio
    ,c.PhoneNumber
    ,c.email
from doc.ClientDocumentMetadata cdm
inner join doc.ClientDocuments d on cdm.FileStreamId = d.stream_id
inner join client.vw_client c on c.clientid = cdm.ClientId 
where cdm.DocumentType = 101
    and cdm.IsDeleted = 0
    and cdm.CreatedOn < '20180417'
    and cdm.FileName like N'%.pdf'