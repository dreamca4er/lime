/
drop table if exists #c
;

select
    c.Passport
    , c.clientid
    , pd.ClientId as MainClientId
    , count(ap.ProductId) as ProductCount
    , mcpc.MainClientProductCount
into #c
from client.vw_Client c
inner join bi.PassportDoubleMainClient pd on pd.PassportNumber = c.Passport
left join prd.vw_AllProducts ap on ap.ClientId = c.clientid
left join client.UserStatusHistory ush on ush.ClientId = c.ClientId
    and ush.IsLatest = 1
outer apply
(
    select count(*) as MainClientProductCount
    from prd.vw_AllProducts ap2
    where ap2.ClientId = pd.ClientId
) mcpc
where exists
    (
        select 1 from prd.vw_AllProducts ap
        inner join client."Identity" i on i.ClientId = ap.ClientId
        where i.Number = c.Passport
    )
    and (ush.Substatus = 4 and ush.CreatedBy = 0x3693 or ush.Substatus != 4)
group by c.Passport, c.clientid, pd.ClientId, mcpc.MainClientProductCount
;
/
drop table if exists #inf
;

select
    c.clientid
    , c.Passport
    , c.PhoneNumber
    , c.substatusName
    , pd.ClientId as MainClient
    , ap.OldProductCount
    , dense_rank() over (partition by c.Passport 
                            order by ap.OldProductCount desc
                                    , p.Priority
                                    , max(cal.OperationDate) desc
                                    , c.ClientId desc) as ClientRank
    , ush.CreatedBy
into #inf
from client.vw_client c
left join #priority p on p.SubstatusId = c.Substatus
left join bi.PassportDoubleMainClient pd on pd.PassportNumber = c.Passport
    and pd.ClientId = c.ClientId
left join client.ClientActionLog cal on cal.ClientId = c.ClientID
    and cal.OperationType = 1
left join client.UserStatusHistory ush on ush.ClientId = c.ClientId
    and ush.IsLatest = 1
outer apply
(
    select count(*) as OldProductCount 
    from prd.vw_AllProducts ap
    where ap.ClientId = c.ClientId 
) ap
where exists
    (
        select distinct #c.Passport
        from #c
        where #c.ProductCount > #c.MainClientProductCount
            and #c.Passport = c.Passport
    )
    and (ush.CreatedBy = 0x3693 or c.status != 4)
group by 
    c.Passport
    , c.ClientId
    , c.Substatus
    , p.Priority
    , c.userid
    , pd.Clientid
    , ap.OldProductCount
    , c.substatusName
    , ush.CreatedBy
    , c.PhoneNumber
/

select * -- update pd set pd.ClientId = i.clientid
from #inf i
inner join bi.PassportDoubleMainClient pd on pd.PassportNumber = i.Passport
where i.ClientRank = 1
    and i.Passport != '2414719592'
;

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
    and i.ClientRank = 1
    and i.Passport != '2414719592'
;

select ush.* -- delete ush
from client.UserStatusHistory ush
inner join #inf i on i.ClientId = ush.ClientId
    and ush.IsLatest = 1
    and i.ClientRank = 1
    and i.Passport != '2414719592'
;

select ush.* -- update ush set Islatest = 1
from client.UserStatusHistory ush
inner join #inf i on i.ClientId = ush.ClientId
    and i.ClientRank = 1
where ush.ModifiedBy = 0x3693
    and i.Passport != '2414719592'
;

select * -- update c set c.status = ush.Status, c.Substatus = ush.Substatus
from client.Client c
inner join #inf i on i.ClientId = c.id
inner join client.UserStatusHistory ush on ush.ClientId = c.id
    and ush.IsLatest = 1
where i.ClientRank = 1
    and i.Passport != '2414719592'
;

drop table if exists #ToDelete
select c.Passport as Number, i.ClientID, c.userid as StsUserId, dense_rank() over (order by c.Passport) % 5 as Pack
into #ToDelete
from #inf i
inner join Client.vw_Client c on c.clientid = i.ClientId
where i.ClientRank != 1
    and c.Status != 4