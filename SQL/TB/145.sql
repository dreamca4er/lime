with a as 
(
    select
        md1.id as ClientDocumentMetadataId
        ,md1.ClientId
        ,md1.CreatedOn
        ,md1.ModifiedBy
        ,md1.Model
        ,md1.ContractNumber
        ,p.id as productId
        ,stp.StartedOn
        ,case
            when count(case when datediff(d, md1.CreatedOn, stp.StartedOn) = 1 then 1 end) over (partition by md1.ClientId)
                = count(*) over (partition by md1.ClientId)
            then 1
        end as HaveSimilar
        ,row_number() over (partition by md1.ClientId order by md1.CreatedOn desc) as rn,
        IsDeleted
--    into dbo.tb145
    from doc.ClientDocumentMetadata md1
    inner join prd.Product p on p.ContractNumber = md1.ContractNumber
    outer apply
    (
        select top 1 stp.StartedOn
        from prd.ShortTermProlongation stp
        where stp.ProductId = p.id
            and stp.IsActive = 1
            and stp.StartedOn >= cast(md1.CreatedOn as date)
        order by stp.StartedOn
    ) stp
    where exists
            (
                select 1
                from doc.ClientDocumentMetadata md2
                where IsDeleted = 1
                    and DocumentType = 105
                    and md1.ClientId = md2.ClientId
                    and md1.ContractNumber = md2.ContractNumber
                group by ClientId, ContractNumber
                having count(*) > 1
            )
        and IsDeleted = 1
        and DocumentType = 105
        and stp.StartedOn is not null
)

--select
--    a.*
--    ,sms.*
--    ,json_modify(a.model, '$.SmsCode', sms.Code)

update cdm
set
    cdm.Model = json_modify(a.model, '$.SmsCode', sms.Code)
    ,cdm.IsDeleted = 0
from a
inner join doc.ClientDocumentMetadata cdm on cdm.id = a.ClientDocumentMetadataId
outer apply
(
    select top 1 
        sms.Code
        ,sms.CreatedOn
    from ecc.SmsCode sms
    where sms.IsVerifed = 1
        and sms.ClientId = a.clientid
        and datediff(d, a.createdon, sms.createdOn) < 60
    order by sms.CreatedOn desc
) sms
where HaveSimilar = 1
    and rn != 1
;

select cdm.Model, cdm.IsDeleted
--delete cdm
from dbo.tb145 t
inner join doc.ClientDocumentMetadata cdm on cdm.id = t.ClientDocumentMetadataId
where HaveSimilar = 1
    and cdm.IsDeleted = 1