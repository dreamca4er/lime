-- drop table dbo.MigrateEccInteractions
create table dbo.MigrateEccInteractions
(
    Id int identity(100000, 1) unique
    , MessageType nvarchar(10) not null
    , MessageId int not null
    , SentOn datetime2
    , SentByUserUid uniqueidentifier
    , SentByUser bit
    , ClientId int
    , ProductId int
    , CreatedOn datetime2
    , CreatedBy uniqueidentifier
    , constraint PK_dbo_MigrateEccInteractions
        primary key(MessageType, MessageId)
)
/*
insert dbo.smstomigrate
select *
from "LIME_MX"."Lime_Mexico".dbo.SmsToMigrate

insert dbo.EmailToMigrate
select *
from "LIME_MX"."Lime_Mexico".dbo.EmailToMigrate

insert dbo.MigrateEccInteractions
(
    MessageId,MessageType,SentOn,SentByUserUid,SentByUser,ClientId,ProductId,CreatedOn,CreatedBy
)
select
    MessageId
    , 'SMS' as MessageType
    , SentOn
    , SentByUserUid
    , SentByUser
    , ClientId
    , ProductId
    , CreatedOn
    , CreatedBy
from dbo.smstomigrate

dbcc CheckIdent('dbo.MigrateEccInteractions', 'reseed', 1100000)

insert dbo.MigrateEccInteractions
(
    MessageId,MessageType,SentOn,SentByUserUid,SentByUser,ClientId,ProductId,CreatedOn,CreatedBy
)
select
    MessageId
    , 'Email' as MessageType
    , SentOn
    , SentByUserUid
    , SentByUser
    , ClientId
    , ProductId
    , CreatedOn
    , CreatedBy
from dbo.Emailtomigrate

dbcc CheckIdent('ecc.Interaction', 'reseed', 1600000)
dbcc CheckIdent('ecc.SmsCommunication', 'reseed', 1100000)
dbcc CheckIdent('ecc.EmailCommunication', 'reseed', 1600000)
select max(id) from ecc.EmailCommunication
select max(id) from ecc.SmsCommunication
select max(id) from ecc.Interaction
*/
/

select max(id)
from dbo.MigrateEccInteractions


set identity_insert ecc.ProviderRequestInfo on
;

insert ecc.ProviderRequestInfo
(
    Id,Request,Response,IsSucceeded,ProviderTypeFullName,CreatedOn,CreatedBy
)
select *
from
(
    values
    (-1, N'Migrate Sms request', N'Migrate Sms response', 1, 'MIGRATE-SMS-PROVIDER', getdate(), 0x44)
    , (-2, N'Migrate Email request', N'Migrate Email response', 1, 'MIGRATE-EMAIL-PROVIDER', getdate(), 0x44)
) p(Id,Request,Response,Success,ProviderTypeFullName,CreatedOn,CreatedBy)
where not exists
    (
        select 1 from ecc.ProviderRequestInfo pri
        where pri.Id in (-1, -2)
    )
set identity_insert ecc.ProviderRequestInfo off
;

dbcc CheckIdent('ecc.ProviderRequestInfo')

/

set identity_insert ecc.Interaction on
;
insert ecc.Interaction 
(
    Id,InteractionStatus,IsAccountable,SentOn,SentByUserUid,SentByUser,ClientId,ProductId,Type,TemplateUid,CreatedOn,CreatedBy
)
select top 100000
    Id
    , 3 as InteractionStatus
    , 0 as IsAccountable
    , SentOn
    , SentByUserUid
    , SentByUser
    , ClientId
    , ProductId
    , iif(MessageType = 'SMS', 2, 3) as Type
    , 0x0 as TemplateUid
    , CreatedOn
    , CreatedBy -- select count(*)
from dbo.MigrateEccInteractions mei
where not exists
    (
        select 1 from ecc.Interaction i
        where i.Id = mei.Id
    )
;
set identity_insert ecc.Interaction off
;
/
/*
select count(*)
from dbo.MigrateEccInteractions mi
inner join dbo.SmsToMigrate sms on sms.MessageId = mi.MessageId
where mi.MessageType = 'sms'
    and not exists
    (
        select 1 from ecc.SmsCommunication sc
        where sc.Id = Mi.Id + 15
    )
*/

declare
    @i int = 1
;

while @i > 0
begin
    set identity_insert ecc.SmsCommunication on
    ;
    
    insert ecc.SmsCommunication 
    (
        Id,Header,PhoneNumber,Body,CrossSystemId,SmsDeliveryStatus,InteractionId,ProviderRequestInfoId,CreatedOn,CreatedBy,StatusType,SentOn
    )
    select top 10000
        Mi.Id + 15 as Id
        , N'Header is not set (It''s sms message)' as Header
        , sms.PhoneNumber
        , sms.Body
        , newid() as CrossSystemId
        , 3 as SmsDeliveryStatus
        , mi.Id as InteractionId
        , -1 as ProviderRequestInfoId
        , sms.CreatedOn
        , sms.CreatedBy
        , 2 as StatusType
        , sms.SentOn
    from dbo.MigrateEccInteractions mi
    inner join dbo.SmsToMigrate sms on sms.MessageId = mi.MessageId
    where mi.MessageType = 'sms'
        and not exists
        (
            select 1 from ecc.SmsCommunication sc
            where sc.Id = Mi.Id + 15
        )
    ;
    
    set identity_insert ecc.SmsCommunication off
    ;
    set @i = @i - 1
end
/
/*
select count(*)
from dbo.MigrateEccInteractions mi
inner join dbo.EmailToMigrate Email on Email.MessageId = mi.MessageId
where mi.MessageType = 'Email'
    and not exists
    (
        select 1 from ecc.EmailCommunication sc
        where sc.Id = Mi.Id + 55
    )
*/

declare
    @i int = 50
;

while @i > 0
begin
    set identity_insert ecc.EmailCommunication on
    ;
        
    insert ecc.EmailCommunication
    (
        Id,EmailFrom,EmailTo,Subject,Body,DeliveryState,InteractionId,ProviderRequestInfoId,CreatedOn,CreatedBy,StatusType,SentOn
    )
    select top 10000
        Mi.Id + 55 as Id
        , email.EmailFrom
        , email.EmailTo
        , email.Subject
        , email.Body
        , 2 as DeliveryState
        , mi.Id as InteractionId
        , -2 as ProviderRequestInfoId
        , email.CreatedOn
        , email.CreatedBy
        , 2 as StatusType
        , email.SentOn
    from dbo.MigrateEccInteractions mi
    inner join dbo.EmailToMigrate email on email.MessageId = mi.MessageId
    where mi.MessageType = 'email'
        and not exists
        (
            select 1 from ecc.EmailCommunication sc
            where sc.Id = Mi.Id + 55
        )
    ;
    
    set identity_insert ecc.EmailCommunication off
    ;
    set @i = @i - 1
end
