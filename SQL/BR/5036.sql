drop table if exists #sms
;

select
    id
    ,SmsCode
into #sms
from "MANGO-DB".LimeZaim_Website.dbo.Credits
;

alter table #sms add primary key(id)
;
/
drop table if exists #model
;

select
    cdm.id
    ,(select 
        cdm.ClientId
        , p.ProductType
        , p.PaymentWay
        , p.Amount
        , p.Period
        , cast('00010101' as datetime2) as StartDate
        , '127.0.0.1' as IpAddress
        , s.SmsCode
        , cdm.ContractNumber
        , cast(1 as bit) as IsPrimary
        , 101 as ProductDocumentType
        , 0 as ProductId
        , case p.PaymentWay
            when 1
            then concat(N'на банковскую карту', N' № ' + cc.NumberMasked) 
            when 2
            then concat(N'на банковский счёт', ' '+ ba.AccountNum, N' в ' + ba.BankName, N', корреспондентский счёт ' + ba.Kor, N', БИК ' + ba.Bik)
            when 3
            then N'на Яндекс.Деньги'
            when 4
            then N'на QIWI VISA WALLET № ' + ph.PhoneNumber
            when 5
            then N'через систему Contact'
        end as ZaimInfo
        , cdm.CreatedOn
        , cast(0 as bit) as IsRegeneration
        , cast(iif(p.PrivilegeFactor = 1, 0, 1) as bit) IsPrivilege
        , p.PrivilegeFactor
        , cast(0 as bit) as "Save"
        , 0 as Format
        , p.ScheduleCalculationType as ScheduleType
        , 1 as Priority
        , null as DocumentNumber
        , cast('00010101' as datetime2) as DateOfRequest
        , null as TemplateOnDate
        , null as CustomRegenerationDomainModel
    from (select 1 as a) b
    for json auto, without_array_wrapper, include_null_values
    ) as Model
    , p.PaymentWay
into #model
from doc.ClientDocumentMetadata cdm
inner join prd.vw_Product p on p.ContractNumber = cdm.ContractNumber
inner join #sms s on s.id = p.Productid
left join client.Phone ph on ph.ClientId = cdm.ClientId
    and ph.PhoneType = 1
left join pmt.CreditCardPaymentInfo ccpi on ccpi.PaymentId = p.BorrowPaymentId
    and p.PaymentWay = 1
left join client.CreditCard cc on cc.Id = ccpi.CreditCardId
outer apply
(
    select top 1
        ba.AccountNum
        ,b.Name as BankName
        ,b.Bik
        ,b.Kor
    from pmt.BankAccountPaymentInfo bapi
    left join client.BankAccount ba on ba.Id = bapi.BankAccountId
    left join client.Bank b on b.Id = ba.BankId
    where bapi.PaymentId = p.BorrowPaymentId
        and p.PaymentWay = 2
) ba
where cdm.Model is null
    and cdm.DocumentType = 101
--    and cdm.CreatedOn < '20180225'
    and cdm.IsDeleted = 0
    and p.Status > 2
/

select count(*) -- update top (20000) cdm set cdm.Model = m.Model
from #model m
inner join doc.ClientDocumentMetadata cdm on m.id = cdm.id
where cdm.Model is null
    and cdm.DocumentType = 101
--    and cdm.CreatedOn < '20180225'
    and cdm.IsDeleted = 0
/

select count(*)
from doc.ClientDocumentMetadata cdm
inner join prd.vw_Product p on p.ContractNumber = cdm.ContractNumber
where cdm.Model is null
    and cdm.DocumentType = 101
    and cdm.IsDeleted = 0
    and p.Status > 2
/

select top 100 cdm.Model
from doc.ClientDocumentMetadata cdm
inner join prd.vw_Product p on p.ContractNumber = cdm.ContractNumber
where cdm.DocumentType = 101
    and cdm.IsDeleted = 0
    and p.Status > 2
    and p.CreatedOn < '20181110'
order by newid()
