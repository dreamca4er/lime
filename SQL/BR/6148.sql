select
    c.ClientId
    , ush.Status as CurrentStatus
    , ushPrev.Status  as PreviousStatus
    , cr.cnt
from br6148_1 c
inner join dbo.FrontendUsers fu on fu.id = c.ClientId
outer apply
(
    select top 1 ush.Status
    from dbo.UserStatusHistory ush
    where ush.UserId = c.ClientId
        and ush.IsLatest = 1
    order by ush.DateCreated desc
) ush
outer apply
(
    select top 1 ush.Status
    from dbo.UserStatusHistory ush
    where ush.UserId = c.ClientId
        and ush.IsLatest = 0
    order by ush.DateCreated desc
) ushPrev
outer apply
(
    select count(*) as cnt
    from dbo.Credits cr
    where cr.UserId = c.ClientId
) cr
;

select ush.* -- update ush set IsLatest = 0, DateLastUpdated = getdate(), LastUpdatedByUserId = 1
from dbo.UserStatusHistory ush
inner join br6148_1 c on c.ClientId = ush.UserId
where IsLatest = 1
;

--insert into dbo.UserStatusHistory (UserId,Status,IsLatest,DateCreated,CreatedByUserId)
select
    ClientId as UserId
    , 9 as Status
    , 1 as IsLatest
    , getdate()
    , 1 as CreatedByUserId
from br6148_1
;

select ubh.* -- update ubh set IsLatest = 0, DateLastUpdated = getdate()
from dbo.UserBlocksHistory ubh
inner join br6148_1 c on c.ClientId = ubh.UserId
where IsLatest = 1
;

select uai.* -- update uai set State = 9
from dbo.UserAdminInformation uai
inner join br6148_1 c on c.ClientId = uai.UserId
;


--insert into dbo.UserCustomLists (CustomlistID,UserId,DateCreated)
select 
    1002 as CustomlistID
    , ClientId as UserId
    , getdate() as DateCreated
from dbo.br6148_1