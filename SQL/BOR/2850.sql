select *
into #sts
from sts.users
where username in
        (
            select u.username
            from sts.users u
            group by u.username, u.passwordhash
            having count(*) > 1
        )
order by username
;
/
select
    id
    ,row_number() over (partition by username order by id) as num
into #stsnum
from #sts
where username in
(
    select
        u.username
    from #sts u-- group by u.username, u.passwordhash
    inner join sts.UserClaims uc on uc.UserId = u.id
        and uc.ClaimType = 'name'
    inner join sts.UserClaims uc1 on uc1.UserId = u.id
        and uc1.ClaimType = 'user_client_id'
    inner join sts.UserClaims uc2 on uc2.UserId = u.id
        and uc2.ClaimType = 'family_name'
    inner join sts.UserClaims uc3 on uc3.UserId = u.id
        and uc3.ClaimType = 'father_name'
    inner join sts.UserClaims uc4 on uc4.UserId = u.id
        and uc4.ClaimType = 'given_name'
    group by u.username, u.passwordhash, uc.ClaimValue, uc1.ClaimValue, uc2.ClaimValue, uc3.ClaimValue, uc4.ClaimValue
    having count(*) > 1
)
;
/
select
    u.* -- delete u
from sts.users u
inner join #stsnum un on un.id = u.id
where un.num != 1
/
drop table if exists #sts2
;

select *
into #sts2
from sts.users
where username in
        (
            select u.username
            from sts.users u
            group by u.username--, u.passwordhash
            having count(*) > 1
        )
/
select username
from #sts2
except
select username
from #sts2 u
inner join sts.UserClaims uc on uc.UserId = u.id
    and uc.ClaimType = 'name'
inner join sts.UserClaims uc1 on uc1.UserId = u.id
    and uc1.ClaimType = 'user_client_id'
inner join sts.UserClaims uc2 on uc2.UserId = u.id
    and uc2.ClaimType = 'family_name'
inner join sts.UserClaims uc3 on uc3.UserId = u.id
    and uc3.ClaimType = 'father_name'
inner join sts.UserClaims uc4 on uc4.UserId = u.id
    and uc4.ClaimType = 'given_name'
group by u.username, uc.ClaimValue, uc1.ClaimValue, uc2.ClaimValue, uc3.ClaimValue, uc4.ClaimValue
having count(*) > 1
/
select 
    u.*
    , uc.ClaimValue, uc1.ClaimValue, uc2.ClaimValue, uc3.ClaimValue, uc4.ClaimValue
from sts.users u
left join sts.UserClaims uc on uc.UserId = u.id
    and uc.ClaimType = 'name'
left join sts.UserClaims uc1 on uc1.UserId = u.id
    and uc1.ClaimType = 'user_client_id'
left join sts.UserClaims uc2 on uc2.UserId = u.id
    and uc2.ClaimType = 'family_name'
left join sts.UserClaims uc3 on uc3.UserId = u.id
    and uc3.ClaimType = 'father_name'
left join sts.UserClaims uc4 on uc4.UserId = u.id
    and uc4.ClaimType = 'given_name'
where username = '79519360137'
/

select distinct
    clientid
    ,fio
    ,LastName
    ,FirstName
    ,FatherName
    ,BirthDate
    ,DateRegistered
    ,PhoneNumber
    ,Passport
    ,Email
    ,status
    ,Substatus
    ,substatusName
    ,IsFrauder
    ,userid
    ,IsDead
    ,IsCourtOrdered
from client.vw_client c
inner join
(
select username
from #sts2 u
inner join sts.UserClaims uc on uc.UserId = u.id
    and uc.ClaimType = 'name'
inner join sts.UserClaims uc1 on uc1.UserId = u.id
    and uc1.ClaimType = 'user_client_id'
inner join sts.UserClaims uc2 on uc2.UserId = u.id
    and uc2.ClaimType = 'family_name'
inner join sts.UserClaims uc3 on uc3.UserId = u.id
    and uc3.ClaimType = 'father_name'
inner join sts.UserClaims uc4 on uc4.UserId = u.id
    and uc4.ClaimType = 'given_name'
group by u.username, uc.ClaimValue, uc1.ClaimValue, uc2.ClaimValue, uc3.ClaimValue, uc4.ClaimValue
having count(*) > 1
) s on s.username = c.PhoneNumber
/
with a as 
(
    select id, row_number() over (partition by username order by LockoutEndDateUtc desc) as rn
    from #sts2
)
delete u
--select u.*
from a
inner join sts.Users u on u.id = a.id
where rn != 1
/

if exists 
    (
        select name from sys.indexes  
        where name = N'IX_UserName_sts_User'
    )
drop index IX_UserName_sts_User on sts.users;
GO

create unique index IX_UserName_sts_User on sts.users(username);