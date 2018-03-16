select *
from client.vw_client
where clientid = 295466

exec sts.sp_chpass 295466
/
create or alter procedure sts.sp_chpass 
@userid int
as
begin
if not exists 
    (
        select 1 from information_schema.tables where table_name = 'userPass' and table_schema = 'dbo'
    )
begin
    create table dbo.userPass
    (
        id int identity(1,1)

        ,createdOn datetime default(getdate())
        ,userid int
        ,userguid uniqueidentifier
        ,username nvarchar(11)
        ,useroldpass nvarchar(max)
    )
end

declare 
    @delay char(8) = '00:00:30'
    ,@userguid uniqueidentifier
    ,@oldpass nvarchar(max)
    -- 123qwe
    ,@newpass nvarchar(max) = '{"Salt":"EXfzc2Kje62Vxuw2cIz7aKEFhbaW5JSplpt2nq07kv0=","Hash":"Q2JHiD4d4tjh0CUBj80QuChsSfnvstPwPJVqFTULQ20rROpO+RAp1pOq6d695A7xjnsNgnwJPdj0cyqXMcz3ol2FrC4i2bijUZeDRhZVnx834lwkFbSXcdiJhxzZcv342u9iJBpYjbj1Uo7hVSn3IpIzeMJ2SdIbavwUA3mkb8hRpSC69DpRqSWWrU5rqQRDvnqcoqQtu7mED+Ln3F48IXNDOA4/+O23UxX66oPRJPRLAFDsF3s062/RLg71yhGSvjf0V6tMo19oFxkRS2NMmUwrkrazIGeVhoGh84jzq/mOLOFbHH3TBzqhJiwwKbHLf0ij1mkQQ4wax2rzfH81yg==","Version":null}'
;

insert into dbo.userPass
(
    userguid, userid, username, useroldpass
)
select 
    u.id
    ,@userid
    ,u.username
    ,u.passwordhash
from sts.Users u
inner join sts.UserClaims uc on uc.UserId = u.id
where uc.ClaimType = 'user_client_id'
    and uc.ClaimValue = cast(@userid as nvarchar(10))
;

select @userguid =
            (
                select top 1 userguid
                from dbo.userPass
                order by id desc
            )
;

select @oldpass =
            (
                select top 1 useroldpass
                from dbo.userPass
                where userguid = @userguid
                order by id desc
            )
;

update u
    set passwordhash = @newpass
from sts.Users u
where id = @userguid
;

select passwordhash
from sts.Users u
where id = @userguid
;
waitfor delay @delay
;
update u
    set passwordhash = @oldpass
from sts.Users u
where id = @userguid
;

select passwordhash
from sts.Users u
where id = @userguid
;
end
go

