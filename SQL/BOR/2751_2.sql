
CREATE or alter function [Col].[tf_op](@DateFrom datetime2, @DateTo datetime2)
returns table as 
return
(
with op as 
(
    select
        op.CollectorId
        ,a.name as Collector
        ,a.collectorGroups
        ,op1.PrevCollectorId
        ,op1.PrevCollectorName
        ,p.ClientId
        ,op.ProductId
        ,op.Date as AssignDate
        ,dateadd(ms, -1, cast(dateadd(d, op.AssignedDays + 1, op.Date) as datetime2)) as LastDayWasAssigned
        ,~op.IsDeleted as ActiveAssign
    from col.OverdueProduct op
    inner join prd.Product p on p.id = op.ProductId
    inner join sts.vw_admins a on a.id = op.CollectorId
    outer apply
    (
        select top 1 
            op1.CollectorId as PrevCollectorId
            ,uc.ClaimValue as PrevCollectorName
        from col.OverdueProduct op1
        inner join sts.UserClaims uc on uc.UserId = op1.CollectorId
            and uc.ClaimType = 'name'
        where op1.ProductId = op.ProductId
            and op1.Date < op.Date
        order by op1.Date desc
    ) op1
    where 1=1
        and op.Date <= @DateTo
        -- Тут мы получаем дату окончания назначение, все нужные манипуляции делаем со входным параметром, чтобы индексы использовались
        and op.Date >= dateadd(ms, -999, dateadd(s, -op.AssignedDays * 24 * 3600 - 59 * 60 - 59, @DateFrom))
        and not exists
            (
                select 1 from col.OverdueProduct op1
                where op1.ProductId = op.ProductId
                    and cast(op1.Date as date) = cast(op.Date as date)
                    and op1.Date > op.date
            )
)

--select
--    sl.ProductId
--    ,sl.StartedOn
--    ,sl.Status
--from prd.vw_statusLog sl
--where exists 
--        (
--            select 1 from op
--            where op.ProductId = sl.ProductId
--                and sl.StartedOn <= op.AssignDate
--                and not exists
--                            (
--                                select 1 from prd.vw_statusLog sl1
--                                where sl1.ProductId = sl.ProductId
--                                    and sl1.StartedOn <= op.AssignDate
--                                    and sl1.StartedOn > sl.StartedOn
--                            )
--        )
select
    op.CollectorId
    ,op.PrevCollectorId
    ,op.Collector
    ,op.ClientId
    ,op.ProductId
--    ,sl.OverdueStart
    ,op.AssignDate
    ,op.LastDayWasAssigned
    ,op.ActiveAssign
from op
--outer apply
--(
--    select top 1 
--        sl.StartedOn as OverdueStart
--        ,sl.status
--    from prd.vw_statusLog sl
--    where sl.ProductId = op.ProductId
--        and sl.StartedOn <= op.AssignDate
--    order by sl.StartedOn desc
--) as sl
--where status = 4

)
GO

drop table if exists #col
;

select *
into #col
from [Col].[vw_op]
where AssignDate <= '20180327'
    and LastDayWasAssigned >= '20180301'
    and overduestart is not null
;

drop table if exists #col4
;

select *
into #col4
from [Col].[tf_op]('20180301', '20180327')
