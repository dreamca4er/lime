--select id
--into #tmp
--from dbo.Credits
--where Status = 5
--    and Way = -2
--
--;

update c
set status = 8
from dbo.Credits c
where id in (select id from #tmp)
;

insert into dbo.CreditStatusHistory
(
    CreditId, Status, DateStarted, DateCreated, CreatedByUserId
)
select
    id
    ,8
    ,getdate()
    ,getdate()
    ,2
from #tmp
;

update ush
set islatest = 0
from dbo.UserStatusHistory ush
where userid in
                (
                select
                    id
                from dbo.FrontendUsers
                where id in (
                                select userid
                                from dbo.credits c
                                where c.id in (select id from #tmp)
                            )
                 )
    and islatest = 1
;

insert into dbo.UserStatusHistory
(
    UserId, Status, IsLatest, DateCreated, CreatedByUserId
)
select
    id
    ,11
    ,1
    ,getdate()
    ,2
from dbo.FrontendUsers
where id in (
                select userid
                from dbo.credits c
                where c.id in (select id from #tmp)
            )