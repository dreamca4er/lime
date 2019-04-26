--drop table if exists #op
;

with d as 
(
    select 
        d.dt1 as MonthStart
        , eomonth(d.dt1) as MonthEnd
    from bi.tf_gendate('20180301', '20190301') d
    where datepart(d, d.dt1) = 1
)

select
    d.*
    , sl.ProductId
    , sl.StatusStart as OverdueStart
--into #op
from d
outer apply
(
    select
        sl.ProductId
        , sl.Status
        , sl.StartedOn as StatusStart
        , datediff(d, sl.StartedOn, d.MonthStart) + 1 as DaysInStatus
    from prd.vw_statusLog sl
    where cast(sl.StartedOn as date) <= d.MonthStart
        and not exists
        (
            select 1 from prd.vw_statusLog sl2
            where cast(sl2.StartedOn as date) <= d.MonthStart
                and sl2.ProductId = sl.ProductId
                and sl2.StartedOn > sl.StartedOn
        )
) sl
where DaysInStatus > 90
    and sl.Status = 4
;

create clustered index IX_op on #op(ProductId, MonthStart) 
;
/
select
    op.MonthStart
    , sum(AmountPaid) / sum(AmountDebt) as RecoveryRate
from #op op
outer apply
(
    select top 1 sl.StartedOn as OverdueEnd
    from prd.vw_statusLog sl
    where sl.ProductId = op.ProductId
        and sl.StartedOn > op.OverdueStart
        and sl.StartedOn <= op.MonthEnd
    order by sl.StartedOn
) ns
outer apply
(
    select top 1 
        (cb.OverdueAmount + cb.OverdueRestructAmount) * -1 as AmountDebt
    from bi.CreditBalance cb
    where cb.ProductId = op.ProductId
        and cb.InfoType = 'debt'
        and cb.DateOperation <= op.MonthStart
    order by cb.DateOperation desc
) oa
outer apply
(
    select
        sum(cb.TotalAmount) as AmountPaid
    from bi.CreditBalance cb
    where cb.InfoType = 'payment'
        and cb.ProductId = op.ProductId
        and cb.DateOperation between op.MonthStart and isnull(ns.OverdueEnd, op.MonthEnd)
) p
group by op.MonthStart