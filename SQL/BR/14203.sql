select  -- update c set Status = 3, Substatus = 304, UserBlockingPeriod = 3600 
from client.client c
where c.id = 420568
;

select * -- update ush set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from client.UserStatusHistory ush
where ush.ClientId = 420568
    and IsLatest = 1
;

insert into client.UserStatusHistory (ClientId,Status,IsLatest,CreatedOn,CreatedBy,BlockingPeriod,Substatus)
select
    420568 as ClientId
    , 3 as Status
    , 1 as IsLatest
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 3600 as BlockingPeriod
    , 304 as Substatus
;
    
select PhoneNumber -- update p set PhoneNumber = 70000000000
from client.Phone p
where ClientId = 420568
    and PhoneType = 1
;

select UserName -- update u set PasswordHash = '-1'
from sts.users u
where id = '607DF5E4-069E-40C8-8DBC-A2CAED500E08'
;

--insert bi.PassportDoubleMainClient (ClientId, PassportNumber)
select ClientId, Passport
from client.vw_client
where ClientId = 420568
except
select ClientId, PassportNumber 
from bi.PassportDoubleMainClient
where PassportNumber = '6705554109' 