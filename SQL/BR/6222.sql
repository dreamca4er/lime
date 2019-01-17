select
    c.ClientId
    , ush.Status as CurrentStatus
    , ushPrev.Status  as PreviousStatus
    , cr.cnt
into #needed
from #cl c
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
where ush.Status = 6
;

select ush.* -- update ush set IsLatest = 0, DateLastUpdated = getdate(), LastUpdatedByUserId = 1
from dbo.UserStatusHistory ush
inner join #needed c on c.ClientId = ush.UserId
where IsLatest = 1
;

--insert into dbo.UserStatusHistory (UserId,Status,IsLatest,DateCreated,CreatedByUserId)
select
    ClientId as UserId
    , 9 as Status
    , 1 as IsLatest
    , getdate()
    , 1 as CreatedByUserId
from #needed
;

select ubh.* -- update ubh set IsLatest = 0, DateLastUpdated = getdate()
from dbo.UserBlocksHistory ubh
inner join #needed c on c.ClientId = ubh.UserId
where IsLatest = 1
;

select uai.* -- update uai set State = 9
from dbo.UserAdminInformation uai
inner join #needed c on c.ClientId = uai.UserId
;


--insert into dbo.UserCustomLists (CustomlistID,UserId,DateCreated)
select 
    1003 as CustomlistID
    , ClientId as UserId
    , getdate() as DateCreated
from #needed

select *
from #needed
