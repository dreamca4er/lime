select *
from dbo._CreditContractsForMigration

select *
from dbo._DocumentsForMigration
/

set transaction isolation level read uncommitted

insert into dbo._CreditContractsForMigration
select top 10000
    id as CreditId
    ,DogovorNumber as CreditNumber
    ,cfm.userid
    ,0 as HasBeenTransferred
from dbo.vw_creditsForMigration cfm
where not exists 
        (
            select 1 from dbo._CreditContractsForMigration cfmt
            where cfmt.CreditId = cfm.id
        )
;

/

set transaction isolation level read uncommitted

drop table if exists #tmp
;

select top 60000
    ud.id as DocumentId
    ,ud.UserId
into #tmp
--set transaction isolation level read uncommitted select count(*)
from dbo.vw_usersForMigration ufm
inner join dbo.UserDocuments ud on ud.UserId = ufm.userid
inner join dbo.UserStatusHistory ush on ush.UserId = ufm.userid
where ush.IsLatest = 1
--    and ush.Status not in (6, 12)
    and not exists 
        (
            select 1 from dbo._DocumentsForMigration dfm
            where dfm.UserId = ud.UserId
        )
;

/*
select *
from #tmp
*/

update ud
set ud.DateCreated = dateadd(millisecond, ud.Type * 10, format(ud.DateCreated, 'yyyyMMdd HH:mm:ss'))
from dbo.UserDocuments ud
inner join #tmp t on t.DocumentId = ud.id
;

insert dbo._DocumentsForMigration
select
    DocumentId
    ,UserId
    ,0 as HasBeenTransferred
    ,null as SkipDeleted
from #tmp
/

select
    HasBeenTransferred
    ,count(*)
from dbo._DocumentsForMigration
group by HasBeenTransferred

select *
from dbo._CreditContractsForMigration
where HasBeenTransferred = 0

select *
from prd.product
where id 