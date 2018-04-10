drop table if exists #d
;

select
    cdm.id
    ,cdm.ClientId
    ,stp.productid
    ,cdm.ContractNumber
    ,cdm.CreatedOn as DocCreatedOn
    ,stp.StartedOn as ProlongCreatedOn
    ,cdm.Model
into #d
from doc.ClientDocumentMetadata cdm
cross apply
(
    select top 1 stp.StartedOn, p.Id as productid
    from prd.ShortTermProlongation stp
    inner join prd.Product p on p.id = stp.ProductId
        and p.ContractNumber = cdm.ContractNumber
    where p.ClientId = cdm.ClientId
        and stp.IsActive = 1
        and cast(stp.StartedOn as date) >= cast(cdm.CreatedOn as date)
     order by stp.StartedOn
) stp
where IsDeleted = 1
    and DocumentType = 105
    and CreatedOn >= '20180301'
    and CreatedOn < '20180401'
    and ContractNumber in
        (
            select ContractNumber
            from doc.ClientDocumentMetadata
            where IsDeleted = 1
                and DocumentType = 105
                and CreatedOn >= '20180301'
                and CreatedOn < '20180401'
            --    and ClientId = 1714638
            group by ContractNumber
            having count(*) > 1
        )
    and json_value(model, '$.SmsCode') is null
    and model is not null
;

select model
from doc.ClientDocumentMetadata
where id = 538350

--update cdm
--set cdm.model = json_modify(d.model, '$.SmsCode', sms.code)
select d.*
from #d d
inner join doc.ClientDocumentMetadata cdm on cdm.Id = d.id
outer apply
(
    select top 1 
        reverse(substring(reverse(sms.Message), 1, 4)) as code
        ,sms.CreatedOn
    from ecc.SmsCommunication sms
    where sms.ClientId = d.ClientId
        and sms.CreatedOn >= '20180301'
        and sms.CreatedOn < '20180401'
        and cast(sms.CreatedOn as date) >= cast(d.DocCreatedOn as date)
        and cast(sms.CreatedOn as date) <= cast(d.ProlongCreatedOn as date)
        and sms.Message like '%' + replicate('[0-9]', 4)
    order by sms.CreatedOn desc
) sms
where not exists 
        (
            select 1 from #d d1
            where d1.ContractNumber = d.ContractNumber
                and d1.DocCreatedOn > d.DocCreatedOn 
        )

