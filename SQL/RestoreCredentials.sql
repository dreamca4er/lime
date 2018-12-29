declare
    @guid uniqueidentifier = newid()
    ,@hash nvarchar(max) = '{"Salt":"EXfzc2Kje62Vxuw2cIz7aKEFhbaW5JSplpt2nq07kv0=","Hash":"Q2JHiD4d4tjh0CUBj80QuChsSfnvstPwPJVqFTULQ20rROpO+RAp1pOq6d695A7xjnsNgnwJPdj0cyqXMcz3ol2FrC4i2bijUZeDRhZVnx834lwkFbSXcdiJhxzZcv342u9iJBpYjbj1Uo7hVSn3IpIzeMJ2SdIbavwUA3mkb8hRpSC69DpRqSWWrU5rqQRDvnqcoqQtu7mED+Ln3F48IXNDOA4/+O23UxX66oPRJPRLAFDsF3s062/RLg71yhGSvjf0V6tMo19oFxkRS2NMmUwrkrazIGeVhoGh84jzq/mOLOFbHH3TBzqhJiwwKbHLf0ij1mkQQ4wax2rzfH81yg==","Version":null}'
    ,@clientid int = 1259567
;

--insert sts.users
--(
--    EmailConfirmed,PasswordHash,PhoneNumberConfirmed,TwoFactorEnabled,LockoutEnabled,AccessFailedCount,UserName,Id,IsEmployee
--)
select
    0 as EmailConfirmed
    , @hash as PasswordHash
    , 1 as PhoneNumberConfirmed
    , 0 as TwoFactorEnabled
    , 0 as LockoutEnabled
    , 0 as AccessFailedCount
    , PhoneNumber as UserName
    , @guid
    , 0 as IsEmployee
from client.vw_client
where clientid = @clientid

--insert sts.UserClaims
--(
--    ClaimType,ClaimValue,UserId
--)
SELECT 'family_name' AS ClaimType,LastName AS ClaimValue,@guid AS UserId
from client.Client
where id = @clientid
UNION ALL
SELECT 'father_name' AS ClaimType,FatherName AS ClaimValue,@guid AS UserId
from client.Client
where id = @clientid
UNION ALL
SELECT 'given_name' AS ClaimType,FirstName AS ClaimValue,@guid AS UserId
from client.Client
where id = @clientid
UNION ALL
SELECT 'name' AS ClaimType,concat(FirstName, ' ', FatherName) AS ClaimValue,@guid AS UserId
from client.Client
where id = @clientid
UNION ALL
SELECT 'user_client_id' AS ClaimType,cast(id as nvarchar(100)) AS ClaimValue,@guid AS UserId
from client.Client
where id = @clientid

--insert sts.UserRoles
select
    @guid as ClientId
    ,id as RoleId
from sts.roles
where name = 'Client'

print @guid

select * -- update c set Status = 2, Substatus = 203
from client.Client c
where id = @clientid

select *
from client.UserStatusHistory
where ClientId = @clientid
