
CREATE PROCEDURE [Col].[tf_AvgPortfolio] (@DateFrom date, @DateTo date, @CollectorId uniqueidentifier = null) as 

drop table if exists #dt
;

drop table if exists #op
;

select top (datediff(d, @dateFrom, @dateTo) + 1) 
    dateadd(d, row_number() over (order by s.name) - 1, @dateFrom) d
into #dt
from sys.sysobjects s
;

select 
    op.CollectorId
    ,op.ProductId
    ,op.ClientId
    ,op.AssignDate
    ,op.LastDayWasAssigned
into #op
from col.tf_op(@datefrom, @dateto) op
where op.CollectorId = @CollectorId or @CollectorId is null
;

select
    dt.d as Date
    ,op.CollectorId
    ,sum(cb.TotalDebt) as Portfolio
    ,count(distinct op.ClientId) as ClientCount
from #op op
inner join #dt dt on op.AssignDate < dateadd(d, 1, dt.d)
    and op.LastDayWasAssigned > dt.d
cross apply
(
    select top 1 TotalDebt
    from bi.CreditBalance cb
    where cb.ProductId = op.ProductId
        and cb.DateOperation <= dt.d
        and cb.InfoType = 'debt'
    order by cb.DateOperation desc
) cb
group by 
    dt.d
    ,op.CollectorId
;
GO
