declare 
    @dateFrom date = '20180325'
    ,@dateTo date = '20180326'
;

drop table if exists #pay
;

drop table if exists #col
;

-- Выгружаем платежи за период
select
    ProductId
    ,mm.Date as PayDate
    ,isnull(sum(case when accNumber like '48801%' then SumKtNt end), 0) as body
    ,isnull(sum(case when accNumber not like '48801%' then SumKtNt end), 0) as other
into #pay
from acc.vw_mm mm
where date between @dateFrom and @dateTo
    and isDistributePayment = 1
    and substring(accNumber, 1, 5) in ('48801', '48802', '48803', N'Штраф') 
group by 
    ProductId
    ,mm.Date
;

select
    op.CollectorId
    ,op.Collector
    ,op.ClientId
    ,op.productid
    ,op.OverdueStart
    ,op.AssignDate
    ,op.LastDayWasAssigned
--    ,datediff(d, op.OverdueStart, p.PayDate) + 1 as OverdueDays
--    ,p.PayDate
--    ,p.body
--    ,p.other
into #col
from Col.vw_op op
--inner join #pay p on p.productid = op.productid
--    and p.PayDate between op.AssignDate and op.LastDayWasAssigned
where op.OverdueStart is not null
    and AssignDate <= @dateTo
    and LastDayWasAssigned >= @dateFrom
;

select 
    c.CollectorId
    ,c.Collector
    ,a.collectorGroups
    ,c.ClientId
    ,c.productid
    ,c.OverdueStart
    ,c.AssignDate
    ,op.LastDayWasAssigned
    ,datediff(d, c.OverdueStart, p.PayDate) + 1 as OverdueDays
    ,p.PayDate
    ,p.body
    ,p.other
from #col c
inner join sts.vw_admins a on a.id = c.CollectorId
inner join #pay p on p.productid = c.productid
    and p.PayDate between c.AssignDate and c.LastDayWasAssigned

/
