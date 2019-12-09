with d as 
(
    select
        sc.ProductId
        , sum(case when sc.SumType = 1002 then Sum * -1 else 0 end) as OverdueAmount
        , sum(case when sc.SumType = 1004 then Sum * -1 else 0 end) as OverdueRestructAmount
        , sum(case when sc.SumType = 2002 then Sum * -1 else 0 end) as OverduePercent
        , sum(case when sc.SumType = 2004 then Sum * -1 else 0 end) as OverdueRestructPercent
        , sum(case when sc.SumType = 4011 then Sum * -1 else 0 end) as Commission
        , sum(case when sc.SumType = 3021 then Sum * -1 else 0 end) as Fine
    from Borneo.acc.ProductSumChange sc
    where sc.ProductType in (1, 2)
        and sc.State = 2
        and sc.SumType in (1002, 1004, 2002, 2004, 4011, 3021)
        and sc.BusinessDate < '20191201'
    group by sc.ProductId
)
      
select
    per.StartedOn as "Год/месяц старта кредита"
    , od.Diap as "Дней просрочки"
    , count(*) as "Кол-во"
    , isnull(sum(OverdueAmount * -1), 0) + isnull(sum(OverdueRestructAmount * -1), 0) as "Просроченное тело"
    , isnull(sum(OverduePercent * -1), 0) + isnull(sum(OverdueRestructPercent * -1), 0) as "Просроченные проценты"
--    , sum(Commission * -1) as DebtCommission
--    , sum(Fine * -1) as DebtFine
from prd.vw_product p
outer apply
(
    select
        case 
            when p.StartedOn < '20190101'
            then dateadd(yy, datediff(yy, '1900', p.StartedOn), '1900')
            else dateadd(mm, datediff(mm, '1900', p.StartedOn), '1900')
        end as StartedOn
) per
outer apply
(
    select top 1 sl.Status, sl.StartedOn
    from prd.vw_statusLog sl
    where sl.ProductId = p.ProductId
        and sl.StartedOn < '20191201'
    order by sl.StartedOn desc
) sl3011
outer apply
(
    select 
        case 
            when datediff(dd, sl3011.StartedOn, '20191130') + 1 between 1 and 30
            then '1. 1-30'
            when datediff(dd, sl3011.StartedOn, '20191130') + 1 between 31 and 60
            then '2. 31-60'
            when datediff(dd, sl3011.StartedOn, '20191130') + 1 between 61 and 90
            then '3. 61-90'
            when datediff(dd, sl3011.StartedOn, '20191130') + 1 between 91 and 180
            then '4. 91-180'
            when datediff(dd, sl3011.StartedOn, '20191130') + 1 between 181 and 360
            then '5. 181-360'
            when datediff(dd, sl3011.StartedOn, '20191130') + 1 > 360
            then '6. 360+'
        end as Diap
) od
left join d on d.ProductId = p.ProductId
where p.Status > 2
    and sl3011.Status = 4
    and p.StartedOn >= '20170101'
group by per.StartedOn, od.Diap