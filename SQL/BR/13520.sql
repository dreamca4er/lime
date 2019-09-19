declare
    @ClientId int = 475235
;

declare
    @PassportNumber nvarchar(10) = 
    (
        select Number
        from client."Identity"
        where clientid = @ClientId
    )
;

// Смотрим, чтобы основной ЛК на данный момент был дублем-мошенником
if not exists
    (
        select 1
        from client."Identity" c
        where 1=1
            and c.ClientId = @ClientId
            and exists
            (
                select 1 from client.vw_client c2
                inner join bi.PassportDoubleMainClient pd on pd.PassportNumber = c2.Passport
                where c2.Passport = c.Number
                    and c2.IsFrauder = 1
            )
    )
    select 1 --return
;

// Выпиливаем мошеннический основной ЛК
delete pd
from bi.PassportDoubleMainClient pd
where pd.PassportNumber = @PassportNumber
;

// Возвращаем целевой ЛК из удаленных

drop table if exists #inf
;

select
    c.clientid
    , c.Passport
    , c.PhoneNumber
into #inf
from client.vw_client c
where c.clientid = @ClientId

/

select
    u.PasswordHash
    , u.UserName
    , i.Phonenumber
    , replace(u.PasswordHash, 'BR-9336_', '')
-- update u set u.username = i.Phonenumber, u.PasswordHash = replace(u.PasswordHash, 'BR-9336_', '')
from sts.UserClaims uc
inner join #inf i on i.clientid = uc.ClaimValue
inner join sts.users u on u.id = uc.UserId
where uc.ClaimType = 'user_client_id'

select ush.* -- delete ush
from client.UserStatusHistory ush
inner join #inf i on i.ClientId = ush.ClientId
    and ush.IsLatest = 1
;

select ush.* -- update ush set Islatest = 1
from client.UserStatusHistory ush
inner join #inf i on i.ClientId = ush.ClientId
where ush.ModifiedBy = 0x3693
;

select * -- update c set c.status = ush.Status, c.Substatus = ush.Substatus
from client.Client c
inner join #inf i on i.ClientId = c.id
inner join client.UserStatusHistory ush on ush.ClientId = c.id
    and ush.IsLatest = 1
;
/

update c set c.Status = 3, Substatus = 304, UserBlockingPeriod = 3600
from client.Client c
inner join #inf i on i.ClientId = c.id
;

update ush set Islatest = 0
from client.UserStatusHistory ush
inner join #inf i on i.ClientId = ush.ClientId
where ush.Islatest = 1
;

insert into client.UserStatusHistory (ClientId,Status,IsLatest,CreatedOn,CreatedBy,BlockingPeriod,Substatus)
select
    ClientId
    , 3
    , 1 as IsLatest
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 3600
    , 304
from #inf