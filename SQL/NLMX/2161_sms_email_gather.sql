drop table if exists dbo.SmsToMigrate
;

select
    sms.Id as MessageId
    , sh.DateApply as SentOn
    , sh.SentByUserUid
    , case
        when ci.Id is null and sms.Type = 7
        then 1
        when ci.Id is null
        then 0
        when sms.Type = 7
        then 1
        else 0
    end as SentByUser
    , sms.UserId as ClientId
    , ci.CreditId as ProductId
    , sms.CreatedOn
    , cast(cast(sms.CreatedBy as binary(8)) as uniqueidentifier) as CreatedBy
    
    , sms.PhoneNumber
    , sms.Message as Body
into dbo.SmsToMigrate
from "Lime_Mexico".dbo.SmsMessages sms
left join "Lime_Mexico".dbo.SmsInteractions i on i.SmsMessageId = sms.Id
left join "Lime_Mexico".dbo.CreditInteractions ci on ci.Id = i.CreditInteractionId
outer apply
(
    select top 1 
        sh.DateApply
        , cast(cast(sh.CreatedBy as binary(8)) as uniqueidentifier) as SentByUserUid
    from "Lime_Mexico".dbo.SmsStatusHistory sh
    where sh.SmsMessageId = sms.Id
        and sh.Status = 512
    order by sh.DateApply desc
) sh
where 1=1
    and sh.DateApply is not null
    and
    (
        ci.Id is null and sms.Type in (1, 2, 6, 7, 8, 9, 10, 28)
        or
        ci.Id is not null and (sms.Type in (5, 7) or sms.Type between 11 and 26)
    )
;
   
drop table if exists dbo.EmailToMigrate
;

select 
    email.Id as MessageId
    , sh.DateApply as SentOn
    , sh.SentByUserUid
    , case 
        when email.Type = 2
        then 1 
        else 0
    end as SentByUser
    , email.UserId as ClientId
    , ci.CreditId as ProductId
    , email.CreatedOn
    , cast(cast(email.CreatedBy as binary(8)) as uniqueidentifier) as CreatedBy
    
    , email."From" as EmailFrom
    , email."To" as EmailTo
    , email.Subject
    , email.Body
into dbo.EmailToMigrate
from "Lime_Mexico".dbo.EmailMessages email
left join "Lime_Mexico".dbo.EmailInteractions i on i.EmailMessageId = email.Id
left join "Lime_Mexico".dbo.CreditInteractions ci on ci.Id = i.CreditInteractionId
outer apply
(
    select top 1 
        sh.DateApply
        , cast(cast(sh.CreatedBy as binary(8)) as uniqueidentifier) as SentByUserUid 
    from "Lime_Mexico".dbo.EmailStatusHistory sh
    where sh.EmailMessageId = email.Id
        and sh.Status = 64
    order by sh.DateApply
) sh
where 1=1
    and
    (
        ci.Id is null and email.Type in (3, 20, 21)
        or 
        ci.Id is not null and email.Type in (2, 7, 14, 15, 16, 19)
    )

