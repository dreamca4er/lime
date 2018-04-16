update cap
set cap.num = a.id
(
    select
        PaymentId
        ,CreditCardId
        ,row_number() over (partition by CreditCardId order by CreatedOn desc) as rn
        ,dense_rank() over (order by CreditCardId desc) + 400000 as id
    from dbo.CardAcknowledgePayment cap
    where ContractNumber is null
) a
inner join dbo.CardAcknowledgePayment cap on cap.PaymentId = a.PaymentId
    and cap.CreditCardId = a.CreditCardId
where a.rn = 1


/
SET IDENTITY_INSERT pmt.Payment ON;

insert into pmt.Payment
(
    id
    ,Amount
    ,Currency
    ,PaymentDirection
    ,PaymentStatus
    ,PaymentType
    ,PaymentWay
    ,PaymentKind
    ,"Order"
    ,OrderDescription
    ,ProcessedOn
    ,CreatedOn
    ,CreatedBy
)
select
    num as id
    ,Amount as Amount
    ,'810' as Currency
    ,PaymentDirection
    ,PaymentStatus
    ,PaymentType
    ,PaymentWay
    ,PaymentKind
    ,OrderId as "Order"
    ,OrderDescription as OrderDescription
    ,CreatedOn as ProcessedOn
    ,CreatedOn as CreatedOn
    ,cast(0x0 as uniqueidentifier) as CreatedBy
from dbo.CardAcknowledgePayment cap
where  exists 
            (
                select 1 from client.CreditCard cc
                where cc.Id = cap.CreditCardId
            )

SET IDENTITY_INSERT pmt.Payment OFF;

/

insert into pmt.CreditCardPaymentInfo
(
    Is3DSecure
    ,NumberMasked
    ,CreditCardId
    ,PaymentId
    ,CreatedOn
    ,CreatedBy
    ,AcquiringProvider
)
select
    Is3DSecure as Is3DSecure
    ,cc.NumberMasked as NumberMasked
    ,cc.id as CreditCardId
    ,cap.num as PaymentId
    ,cap.CreatedOn as CreatedOn
    ,cast(0x0 as uniqueidentifier) as CreatedBy
    ,2 as AcquiringProvider
from dbo.CardAcknowledgePayment cap 
inner join client.CreditCard cc on cc.Id = cap.CreditCardId
inner join pmt.Payment p on p.id = cap.num
where num is not null

update statistics pmt.CreditCardPaymentInfo

/

select top 100 
    p.id
    ,cap.CreditCardId -- delete p
from dbo.CardAcknowledgePayment cap
inner join pmt.Payment p on p.Id = cap.num 
where not exists 
            (
                select 1 from pmt.CreditCardPaymentInfo ccpi
                where ccpi.PaymentId = p.id
            )
    and not exists 
            (
                select 1 from client.CreditCard cc
                where cc.Id = cap.CreditCardId
            )
update statistics pmt.Payment
            
