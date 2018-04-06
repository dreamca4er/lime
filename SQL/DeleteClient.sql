declare 
    @clientId int
    ,@guid uniqueidentifier
    ,@phone nvarchar(11) = ''
;
    
select *
from client.vw_client
where PhoneNumber = @phone
;

select @clientId = clientid
from client.vw_client
where PhoneNumber = @phone
;

select *
from prd.vw_Product
where clientId = @clientId
;

select @guid = userid
from client.vw_client
where PhoneNumber = @phone
;

delete --select *
from client.Client
where id = @clientId
;

delete --select *
from sts.Users
where id = @guid
;

