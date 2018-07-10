select distinct
    cdm.id
    ,p.CreatedOn
    ,(select 
        p.Amount
        ,p.ClientId
        ,p.ContractNumber
        ,p.CreatedOn
        ,c.IpAddress
        ,cast(1 as bit) as IsPrimary
        ,cast(case when p.PrivilegeFactor < 1 then 0 else 1 end as bit) as IsPrivilege
        ,cast(1 as bit) as IsRegeneration
        ,null as OldContractNumber
        ,p.PaymentWay
        ,p.Period
        ,p.PrivilegeFactor
        ,101 as ProductDocumentType
        ,0 as ProductId
        ,p.ProductType
        ,case when p.ContractNumber = '0305121002' then 751187 else 704242 end as SmsCode
        ,cast('00010101' as datetime2) as StartDate
        ,N'на банковскую карту № ' + cc.NumberMasked as ZaimInfo
    from (values (1)) a(b)
    for json auto, without_array_wrapper, include_null_values) as model
    ,cdm.model as OldModel
into #tmp
from doc.ClientDocumentMetadata cdm
inner join prd.vw_Product p on p.ContractNumber = cdm.ContractNumber
inner join client.Client c on c.Id = p.ClientId
inner join pmt.payment pay on pay.ContractNumber = p.ContractNumber
inner join pmt.CreditCardPaymentInfo ccpi on ccpi.PaymentId = pay.id
inner join client.CreditCard cc on cc.id = ccpi.CreditCardId
where cdm.ClientId = 305121 
    and cdm.DocumentType = 101
/

select 
    cdm.id
    ,cdm.CreatedOn
    ,cdm.model
    ,t.CreatedOn
    ,t.Model
-- update cdm set cdm.CreatedOn = t.CreatedOn, cdm.model = t.model
from doc.ClientDocumentMetadata cdm
inner join #tmp t on t.id = cdm.id
