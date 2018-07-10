

declare
    @contractNUmber nvarchar(10) = '1335096005'
    ,@smsCode nvarchar(10) = '508042'
;

select *
from doc.ClientDocumentMetadata cdm
where ContractNumber = @contractNUmber
;

select --update cdm set FileName = replace(FileName, '.pdf', '.html'), Model = 
    (
        select 
            p.Amount
            ,p.ClientId
            ,p.ContractNumber
            ,cdm.CreatedOn
            ,isnull(nullif(p.IpAddress, ''), '192.168.1.1') as IpAddress
            ,cast(1 as bit) as IsPrimary
            ,cast(0 as bit) as IsPrivilege
            ,cast(0 as bit) as IsRegeneration
            ,null as OldContractNumber
            ,p.PaymentWay
            ,p.Period
            ,p.PrivilegeFactor
            ,cdm.DocumentType as ProductDocumentType
            ,0 as ProductId
            ,p.ProductType
            ,@smsCode as SmsCode
            ,cast('00010101' as datetime2) as StartDate
            ,N'на банковскую карту ' + p.NumberMasked as ZaimInfo
        from (select 1 as b) a
        for json auto, without_array_wrapper, include_null_values 
    )
from doc.ClientDocumentMetadata cdm
cross join
(
select
    p.Amount
    ,p.ClientId
    ,p.ContractNumber
    ,c.IpAddress
    ,p.PaymentWay
    ,p.Period
    ,p.PrivilegeFactor
    ,p.ProductType
    ,cc.NUmbermasked
from prd.vw_Product p
inner join client.Client c on p.ClientId = c.id
left join pmt.Payment pay on pay.contractnumber = p.contractnumber 
    and pay.PaymentDirection = 1
    and pay.PaymentStatus in (3, 5)
left join pmt.CreditCardPaymentInfo ccpi on ccpi.PaymentId = pay.id
left join Client.CreditCard cc on cc.id = ccpi.CreditCardId
where p.ContractNumber = @contractNUmber
) p
where cdm.contractnumber = @contractNUmber
    and cdm.DocumentType = 101
;

select *
from doc.ClientDocumentMetadata cdm
where ContractNumber = @contractNUmber
;