select
    c.clientid
    ,c.PhoneNumber
    ,c.userid
    ,u.UserName-- update u set UserName = c.PhoneNumber
from client.vw_client c
inner join sts.UserClaims uc on uc.ClaimType = 'user_client_id'
    and uc.ClaimValue = c.clientid
inner join sts.users u on u.id = uc.userid
where c.clientid = 93937

