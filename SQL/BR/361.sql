drop table if exists #cdm101
;

select 
    cdm.id as ClientDocumentMetadataId
    ,cdm.ContractNumber
    ,cdm.ClientId
    ,p.PaymentWay
    ,replace(cdm.FileName, 'pdf', 'html') as FileName
    ,(
    select
        p.Amount as Amount
        ,p.ClientId
        ,cdm.ContractNumber
        ,cdm.CreatedOn
        ,coalesce(nullif(c.IpAddress, ''), json_value(cdm.Model, '$.IpAddress'), '127.0.0.1') as IpAddress
        ,cast(1 as bit) as IsPrimary
        ,cast(1 as bit) as IsRegeneration
        ,cast(null as bit) as OldContractNumber
        ,p.PaymentWay
        ,p.Period
        ,cdm.DocumentType as ProductDocumentType
        ,0 as ProductId
        ,p.ProductType
        ,coalesce(json_value(cdm.Model, '$.SmsCode'), sms.code, '0000') as SmsCode
        ,cast('00010101 00:00:00' as datetime2) as StartDate
        ,case 
            when p.PaymentWay = 1 then concat(N'на банковскую карту № ', cc.NumberMasked)
            when p.PaymentWay = 2 then concat(N'на банковский счёт ', ba.AccountNum, N' в ', b.Name, N', корреспондентский счёт ', b.Kor, N', БИК ', b.Bik)
            when p.PaymentWay = 3 then N'через Яндекс.Деньги'
            when p.PaymentWay = 4 then concat(N'на QIWI VISA WALLET № ', case when c.clientid = 1888535 then '79035432583' else c.PhoneNumber end) 
            when p.PaymentWay = 5 then N'через систему Contact'
        end as ZaimInfo
    from (select 1 as a) aa
    for json auto, without_array_wrapper, include_null_values
    ) as Model 
into #cdm101
from doc.ClientDocumentMetadata cdm
inner join prd.vw_product p on p.ContractNumber = cdm.ContractNumber
inner join client.vw_Client c on c.clientid = p.clientId
left join pmt.Payment pm on pm.ContractNumber = p.ContractNumber
    and pm.PaymentDirection = 1
left join pmt.CreditCardPaymentInfo ccpi on ccpi.PaymentId = pm.id
left join client.CreditCard cc on cc.Id = ccpi.CreditCardId
left join pmt.BankAccountPaymentInfo bapi on bapi.PaymentId = pm.id
left join client.BankAccount ba on ba.Id = bapi.BankAccountId
left join client.Bank b on b.Id = ba.BankId
outer apply
(
    select top 1 sms.Code
    from ecc.SmsCode sms
    where sms.ClientId = c.clientid
        and sms.CreatedOn < cdm.CreatedOn
    order by sms.id desc
) sms
where cdm.CreatedOn >= '20180225'
    and cdm.CreatedOn <= '20180422'
    and cdm.DocumentType = 101
    and p.status > 2
    and p.clientId not in (1884589, 634298) -- Олеся и Никита
;
/
drop table if exists #cdm102_103_104
;
with cdm102_103_104 as 
(
select
    cdm.id as ClientDocumentMetadataId
    ,cdm.ContractNumber
    ,cdm.ClientId
    ,replace(cdm.FileName, 'pdf', 'html') as FileName
    ,cdm.DocumentType
    ,p.PaymentWay
    ,row_number() over (partition by cdm.ContractNumber, cdm.DocumentType order by cdm.CreatedOn desc) as rn
from doc.ClientDocumentMetadata cdm
inner join prd.vw_product p on p.ContractNumber = cdm.ContractNumber
where cdm.CreatedOn >= '20180225'
    and cdm.CreatedOn <= '20180422'
    and cdm.DocumentType in (102, 103, 104)
    and p.status > 2
    and p.clientId not in (1884589, 634298) -- Олеся и Никита
)

select c2.*, json_modify(c1.Model, '$.ProductDocumentType', c2.DocumentType) as Model
into #cdm102_103_104
from #cdm101 c1
inner join cdm102_103_104 c2 on c1.ContractNumber = c2.ContractNumber

/
drop table if exists #cdm105
;

drop table if exists #b
;

drop table if exists #b2
;

with a as 
(
    select 
        cdm.id as ClientDocumentMetadataId
        ,cdm.ContractNumber
        ,cdm.CreatedOn as DocumentCreatedOn
        ,cdm.CreatedBy as DocumentCreatedBy
        ,stp.StartedOn as ProlongStart
        ,datediff(mi, stp.BuiltOn, cdm.CreatedOn) as MinuteDiff
        ,count(*) over (partition by cdm.ContractNumber, ShortTermProlongationId) as cnt
        ,min(datediff(mi, stp.BuiltOn, cdm.CreatedOn)) over (partition by cdm.ContractNumber, ShortTermProlongationId) as MinDiff
        ,json_value(cdm.Model, '$.SmsCode') as ModelCode
        ,p.Amount
        ,p.clientId
        ,p.productid
        ,coalesce(nullif(c.IpAddress, ''), json_value(cdm.Model, '$.IpAddress'), '127.0.0.1') as IpAddress
        ,p.PaymentWay
        ,p.Period
        ,cdm.DocumentType
        ,p.productType
        ,case 
            when p.PaymentWay = 1 then concat(N'на банковскую карту № ', cc.NumberMasked)
            when p.PaymentWay = 2 then concat(N'на банковский счёт ', ba.AccountNum, N' в ', b.Name, N', корреспондентский счёт ', b.Kor, N', БИК ', b.Bik)
            when p.PaymentWay = 3 then N'через Яндекс.Деньги'
            when p.PaymentWay = 4 then concat(N'на QIWI VISA WALLET № ', case when c.clientid = 1888535 then '79035432583' else c.PhoneNumber end) 
            when p.PaymentWay = 5 then N'через систему Contact'
        end as ZaimInfo
        ,replace(cdm.FileName, 'pdf', 'html') as FileName
    from doc.ClientDocumentMetadata cdm
    inner join prd.vw_product p on p.ContractNumber = cdm.ContractNumber
    inner join client.vw_Client c on c.clientId = p.clientId
    left join pmt.Payment pm on pm.ContractNumber = p.ContractNumber
        and pm.PaymentDirection = 1
    left join pmt.CreditCardPaymentInfo ccpi on ccpi.PaymentId = pm.id
    left join client.CreditCard cc on cc.Id = ccpi.CreditCardId
    left join pmt.BankAccountPaymentInfo bapi on bapi.PaymentId = pm.id
    left join client.BankAccount ba on ba.Id = bapi.BankAccountId
    left join client.Bank b on b.Id = ba.BankId
    outer apply
    (
        select top 1
            stp.BuiltOn
            ,stp.StartedOn
            ,stp.Id as ShortTermProlongationId
        from prd.ShortTermProlongation stp
        where stp.ProductId = p.productid
            and stp.IsActive = 1
            and stp.BuiltOn < cdm.CreatedOn
        order by stp.id desc
    ) stp
    where cdm.CreatedOn >= '20180225'
        and cdm.CreatedOn <= '20180422'
        and cdm.DocumentType = 105
        and p.status > 2
        and p.clientId not in (1884589, 634298) -- Олеся и Никита
)

select
    a.*
    ,case when cnt = 1 and MinuteDiff < 2000 or cnt != 1 and MinuteDiff = MinDiff and MinuteDiff < 2000 then 1 end as IsNeeded
into #b
from a
;

select
    b.*
    ,coalesce(b.ModelCode, sms.code, '0000') as SmsCode
into #b2
from #b b
outer apply
(
    select top 1 sms.Code
    from ecc.SmsCode sms
    where sms.ClientId = b.clientid
        and sms.CreatedOn < b.DocumentCreatedOn
    order by sms.id desc
) sms
where b.IsNeeded = 1
;

select
    ClientDocumentMetadataId
    ,ContractNumber
    ,ClientId
    ,PaymentWay
    ,FileName
    ,(
    select
        b.Amount as Amount
        ,b.ClientId
        ,b.ContractNumber
        ,b.DocumentCreatedOn as CreatedOn
        ,b.IpAddress
        ,cast(1 as bit) as IsPrimary
        ,cast(1 as bit) as IsRegeneration
        ,b.ContractNumber as OldContractNumber
        ,b.PaymentWay
        ,b.Period
        ,b.DocumentType as ProductDocumentType
        ,b.ProductId
        ,b.ProductType
        ,b.SmsCode
        ,b.ProlongStart as StartDate
        ,b.ZaimInfo
    from (select 1 as a) aa
    for json auto, without_array_wrapper, include_null_values
    ) as Model 
into #cdm105
from #b2 b

/

--insert into dbo.RegenExample
select
    c.ClientDocumentMetadataId -- update cdm set cdm.FileName = c.FileName, cdm.Model = c.model
from #cdm105 c 
inner join doc.ClientDocumentMetadata cdm on cdm.Id = c.ClientDocumentMetadataId
order by c.ClientDocumentMetadataId
