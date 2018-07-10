declare 
    @dateFrom date = '20180501'
    ,@dateTo date = '20180601'
;
set language russian
;

drop table if exists #CollectorCalls
;

drop table if exists #Portfolio
;

drop table if exists #days
;

drop table if exists #CollectorDays
;

create table #Portfolio
(
    Date date
    ,CollectorId uniqueidentifier
    ,Portfolio numeric(18, 2)
    ,ClientCount int
)
;

select top (datediff(d, @dateFrom, @dateTo) + 1)
    dateadd(d, row_number() over (order by name) - 1, @dateFrom) as Date
into #days
from sys.sysobjects
;

select
    a.id as CollectorId
    ,a.name as CollectorName
    ,a.CollectorGroups
    ,d.Date
    ,datename(month, d.Date) as MonthName
into #CollectorDays
from sts.vw_admins a
cross join #days d
where a.CollectorGroups like '[BC]%'
;

insert #Portfolio
exec [Col].[tf_AvgPortfolio] @dateFrom, @dateTo
;

select
    cc.CollectorId
    ,cc.CallStart
    ,cc.CallEnd
    ,dateadd(minute, 10, cc.CallEnd) as CallEndPlus -- Даем коллектору 10 минут на фиксацию результатов работы
    ,cc.DurationCall
    ,cc.DurationTalk
    ,cc.Error
    ,row_number() over (partition by cc.CollectorId, cast(cc.CallStart as date) 
                        order by cc.CallStart) as rn
into #CollectorCalls
from bi.vw_CollectorCalls cc
where cast(cc.CallStart as date) between @dateFrom and @dateTo
;

with cte(CollectorId, CallStart, CallEndPlus, WorkDuration, CallDuration, rn, UsedElems, CallCount) as 
(
select
    cc.CollectorId
    ,cc.CallStart
    ,cc.CallEndPlus
    ,datediff(s, cc.CallStart, cc.CallEndPlus) as WorkDuration
    ,datediff(s, cc.CallStart, cc.CallEnd) as CallDuration
    ,cc.rn
    ,cast(cc.rn as nvarchar(1000)) as UsedElems
    ,1 as CallCount
from #CollectorCalls cc
where cc.Error is null
    and not exists 
    (
        select 1 from #CollectorCalls cc1
        where cc1.CollectorId = cc.CollectorId
            and cc1.CallStart != cc.CallStart
            and cc.CallStart between cc1.CallStart and cc1.CallEndPlus
    )
    
union all

select
    cc.CollectorId
    ,cte.CallStart
    ,cc.CallEndPlus
    ,datediff(s, cte.CallStart, cc.CallEndPlus) as WorkDuration
    ,datediff(s, cc.CallStart, cc.CallEnd) + cte.CallDuration as CallDuration
    ,cc.rn
    ,cast(cte.UsedElems + ',' + cast(cc.rn as nvarchar(1000)) as nvarchar(1000)) as UsedElems
    ,cte.CallCount + 1 as CallCount
from cte 
inner join #CollectorCalls cc on cte.CollectorId = cc.CollectorId
    and cc.CallStart between cte.CallStart and cte.CallEndPlus
    and cc.rn = cte.rn + 1
where cc.Error is null
    
)

,WorkTime as 
(
    select
        cte.CollectorId
        ,cast(cte.CallStart as date) as Date
        ,sum(cte.WorkDuration) as WorkDayDuration
        ,sum(cte.CallDuration) as CallDuration
        ,sum(cte.CallCount) as EffectiveCallCount
    from cte
    where not exists 
        (
            select 1 from cte cte2
            where cte.CollectorId = cte2.CollectorId
                and cte.CallStart = cte2.CallStart
                and cte2.WorkDuration > cte.WorkDuration
        )
    group by cte.CollectorId, cast(cte.CallStart as date)
)

,AllCalls as 
(
    select
        cc.CollectorId
        ,cast(cc.CallStart as date) as Date
        ,count(*) as AllCallCount
    from #CollectorCalls cc
    group by cc.CollectorId, cast(cc.CallStart as date)
)

,Comments as 
(
    select 
        cci.CreatedBy as CollectorId
        ,cast(cci.CreatedOn as date) as Date
        ,count(case when len(cci.Comment) >= 100 then 1 end) as LongCommentCount
        ,count(case when len(cci.Comment) < 100 then 1 end) as ShortCommentCount
        ,count(distinct cci.ClientId) as ClientCommentCount
    from col.CollectorClientInfo cci
    where cast(cci.CreatedOn as date) between @dateFrom and @dateTo
    group by cci.CreatedBy, cast(cci.CreatedOn as date)
)
/*
,Interaction as 
(
    select
        i.CreatedBy as CollectorId
        ,cast(i.CreatedOn as date) as Date
        ,count(*) as InteractionCount
    from ecc.Interaction i
    inner join sts.vw_admins a on a.Id = i.CreatedBy
    where cast(i.CreatedOn as date) between @dateFrom and @dateTo
        and a.Roles = 'Collector'
        and i.Type in (1, 2)
        and i.Auto = 0
    group by i.CreatedBy, cast(i.CreatedOn as date)
)
*/
select
    cd.*
    ,isnull(wt.WorkDayDuration, 0) as WorkDayDuration
    ,isnull(wt.CallDuration, 0) as CallDuration
    ,isnull(wt.EffectiveCallCount, 0) as EffectiveCallCount
    ,isnull(ac.AllCallCount, 0) as AllCallCount
    ,isnull(c.LongCommentCount, 0) as LongCommentCount
    ,isnull(c.ShortCommentCount, 0) as ShortCommentCount
    ,isnull(c.ClientCommentCount, 0) as ClientCommentCount
    ,isnull(p.ClientCount, 0) as PortfolioClientCount
--    ,isnull(i.InteractionCount, 0) as InteractionCount
from #CollectorDays cd
left join WorkTime wt on wt.CollectorId = cd.CollectorId
    and wt.Date = cd.Date
left join AllCalls ac on ac.CollectorId = cd.CollectorId
    and ac.Date = cd.Date
left join Comments c on c.CollectorId = cd.CollectorId
    and c.Date = cd.Date
left join #Portfolio p on p.CollectorId = cd.CollectorId
    and p.Date = cd.Date
--left join Interaction i on i.CollectorId = cd.CollectorId
--    and i.Date = cd.Date
