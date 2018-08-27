
insert into col.CollectorGroup
 (
    Name, CollectorId
 )
select 'B', 'a21686fb-f04f-43eb-8dc7-8e9d678d574a'

select * -- update op set IsDeleted = 1 
from col.OverdueProduct op
where op.CollectorId in ('a21686fb-f04f-43eb-8dc7-8e9d678d574a')
    and IsDeleted = 0

select * -- delete
from col.CollectorGroup
where CollectorId in ('a21686fb-f04f-43eb-8dc7-8e9d678d574a')

/******************************************************************************/

declare
    @dateFrom date = cast(dateadd(d, -0, getdate()) as date)
    ,@dateTo date = cast(getdate() as date)
;

drop table if exists #tmp
;

create table #tmp
(
    Date Date
    ,CollectorId uniqueidentifier
    ,Portfolio numeric(18, 2)
    ,ClientCount int
)

insert #tmp
exec col.tf_AvgPortfolioOverdue @dateFrom, @dateTo


select
    t.*
    ,a.name
    ,a.CollectorGroups
from  #tmp t
inner join sts.vw_admins a on a.id = t.collectorid
where t.date = '20180615'
select *
from col.OverdueProduct
where CollectorId = '987D2E9E-1516-49AB-80FB-746C302CD7D8'
    and IsDeleted = 0
    /
/******************************************************************************/

select top 10 
    op.id
    ,op.ProductId
    ,op.CollectorId
    ,op.CreatedOn
    ,op.Date
    ,op.AssignedDays
    ,sl.StatusName
    ,sl.StartedOn
    ,op.IsDeleted
--delete op
from col.OverdueProduct op
outer apply
(
    select top 1
        sl.Status
        ,sl.StartedOn
        ,sl.StatusName
    from prd.vw_statusLog sl
    where sl.ProductId = op.ProductId
        and sl.StartedOn <= op.Date
    order by sl.StartedOn desc
) sl
where sl.Status is null
    or sl.status != 4
