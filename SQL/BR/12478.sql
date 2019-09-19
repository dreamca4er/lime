drop table if exists #prodlist
;

select
    p.Productid
    , p.StartedOn
    , dateadd(month, datediff(month, 0, p.StartedOn), 0) as StartMonth
into #prodlist
from prd.vw_product p
where p.Status > 2
    and p.ProductType = 1
    and p.StartedOn >= '20180101'
    and p.StartedOn < '20190401'
;
/
with dates as (
    select cast( dateadd(month, datediff(month, 0, g.dt1), 0) as date) as MonthDt
        , g.dt2 as BeforeDt
    from bi.tf_gendate ('20180101', '20190601') g
    where datepart(day, g.dt2) = 1
)

select p.StartMonth
    , d.MonthDt
    , count(*) qty
    , sum(TotalDebt) as TotalDebt
from #prodlist p
inner join dates d on p.StartedOn <= d.MonthDt
    and p.StartedOn < d.BeforeDt
outer apply (
    select top 1 sl.Status
        , sl.StartedOn
        , case when sl.Status = 4 then datediff(day, sl.StartedOn, d.BeforeDt) end  as OverdueDays 
    from prd.ShortTermStatusLog sl
    where sl.ProductId = p.ProductId
        and sl.startedOn < d.BeforeDt
    order by sl.StartedOn desc
) o
outer apply (
    select top 1 cb.TotalDebt * -1 as TotalDebt
    from bi.CreditBalance cb
    where cb.ProductId = p.ProductId
        and cb.InfoType = 'debt'
        and cb.DateOperation < d.beforeDt
    order by cb.DateOperation desc
) dbt
where 1=1
    and o.OverdueDays > 30
--    and p.Productid = 1020147
group by p.StartMonth
    , d.MonthDt