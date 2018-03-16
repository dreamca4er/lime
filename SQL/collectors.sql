declare
	@dateFrom date = '20180301'
	,@dateTo date = '20180313'
;

    
drop table if exists #part1
;

drop table if exists #part2
;

drop table if exists #pay
;

drop table if exists #ColPeriod
;

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
	op.collectorid
	,op.overduedays
	,op.productid
	,pb.*
	,p.ClientId
	,p.StartedOn
into #part1
from col.OverdueProduct op
inner join prd.Product p on p.id = op.ProductId
outer apply
(
	select 
		sum(case when substring(a.number, 1, 5) = '48801' then saldont end) as amt
		,sum(case when substring(a.number, 1, 5) != '48801' then saldont end) as other
	from acc.vw_acc a
	where a.productid = op.productid
		and substring(a.number, 1, 5) in ('48801', '48802', '48803', N'штраф')
) pb
where op.isdeleted = 0

;

with prodnum as 
(
	select 
		p.productid
		,count(*) as ProdNum
	from prd.vw_product p1
	inner join #part1 p on p1.clientid = p.clientid
		and p1.StartedOn <= p.StartedOn
		and p1.status != 1
	group by p.productid
)

select
    p1.*
	,pn.ProdNum
into #part2
from #part1 p1
inner join prodnum pn on pn.productid = p1.productid
;

select
    op.*
    ,p.PayDate
    ,p.body
    ,p.other
into #ColPeriod
from Col.vw_op op
left join #pay p on p.productid = op.productid
    and p.PayDate between op.AssignDate and op.LastDayWasAssigned
where op.OverdueStart is not null
    and AssignDate <= @dateTo
    and LastDayWasAssigned >= @dateFrom
;

with PayInPeriod as 
(
    select
        cp.CollectorId
        ,sum(body) as AmtPeriod
        ,sum(other) as OtherPeriod
        ,sum(case when datediff(d, OverdueStart, PayDate) + 1 between 1 and 3 then body + other end) as PayPeriod1_3
        ,sum(case when datediff(d, OverdueStart, PayDate) + 1 between 4 and 5 then body + other end) as PayPeriod4_5
        ,sum(case when datediff(d, OverdueStart, PayDate) + 1 between 6 and 10 then body + other end) as PayPeriod6_10
        ,sum(case when datediff(d, OverdueStart, PayDate) + 1 between 11 and 15 then body + other end) as PayPeriod11_15
        ,sum(case when datediff(d, OverdueStart, PayDate) + 1 between 16 and 30 then body + other end) as PayPeriod16_30
        ,sum(case when datediff(d, OverdueStart, PayDate) + 1 between 31 and 45 then body + other end) as PayPeriod31_45
        ,sum(case when datediff(d, OverdueStart, PayDate) + 1 between 46 and 70 then body + other end) as PayPeriod46_70
        ,sum(case when datediff(d, OverdueStart, PayDate) + 1 >= 71 then body + other end) as PayPeriod71Plus
        ,sum(case when datediff(d, AssignDate, PayDate) + 1 between 1 and 3 then body + other end) as AssignDay1_3
        ,sum(case when datediff(d, AssignDate, PayDate) + 1 between 4 and 5 then body + other end) as AssignDay4_5
        ,sum(case when datediff(d, AssignDate, PayDate) + 1 between 6 and 10 then body + other end) as AssignDay6_10
        ,sum(case when datediff(d, AssignDate, PayDate) + 1 between 11 and 15 then body + other end) as AssignDay11_15
        ,sum(case when datediff(d, AssignDate, PayDate) + 1 between 16 and 30 then body + other end) as AssignDay16_30
        ,sum(case when datediff(d, AssignDate, PayDate) + 1 between 31 and 45 then body + other end) as AssignDay31_45
        ,sum(case when datediff(d, AssignDate, PayDate) + 1 between 46 and 70 then body + other end) as AssignDay46_70
        ,sum(case when datediff(d, AssignDate, PayDate) + 1 >= 71 then body + other end) as AssignDay71Plus        
        ,count(case when cp.AssignDate between @dateFrom and @dateTo then 1 end) as AssignPeriod
        ,count(distinct p.clientid) as PayingClientCnt
    from #ColPeriod cp
    left join prd.Product p on p.id = cp.productid
        and cp.PayDate is not null
    group by cp.CollectorId
)
 
,CurrentPortfolio as 
(
    select
        p2.collectorid
        ,isnull(sum(amt), 0) as AmtNow
        ,isnull(sum(other), 0) as OtherNow
        ,count(*) as CntNow
        ,count(case when ProdNum = 1 then 1 end) as num1Now
        ,count(case when ProdNum = 2 then 1 end) as num2Now 
        ,count(case when ProdNum = 3 then 1 end) as num3Now
        ,count(case when ProdNum = 4 then 1 end) as num4Now
        ,count(case when ProdNum >= 5 then 1 end) as num5PlusNow
    from #part2 p2
    group by p2.collectorid
)


select
    a.id
    ,a.name as CollectorName
    ,a.collectorGroups
    ,isnull(pip.AmtPeriod, 0) as AmtPeriod
    ,isnull(pip.OtherPeriod, 0) as OtherPeriod
    ,isnull(pip.PayPeriod1_3, 0) as PayPeriod1_3
    ,isnull(pip.PayPeriod4_5, 0) as PayPeriod4_5
    ,isnull(pip.PayPeriod6_10, 0) as PayPeriod6_10
    ,isnull(pip.PayPeriod11_15, 0) as PayPeriod11_15
    ,isnull(pip.PayPeriod16_30, 0) as PayPeriod16_30
    ,isnull(pip.PayPeriod31_45, 0) as PayPeriod31_45
    ,isnull(pip.PayPeriod46_70, 0) as PayPeriod46_70
    ,isnull(pip.PayPeriod71Plus, 0) as PayPeriod71Plus
    ,isnull(pip.AssignPeriod, 0) as AssignPeriod
    ,isnull(pip.AssignDay1_3, 0) as AssignDay1_3
    ,isnull(pip.AssignDay4_5, 0) as AssignDay4_5
    ,isnull(pip.AssignDay6_10, 0) as AssignDay6_10
    ,isnull(pip.AssignDay11_15, 0) as AssignDay11_15
    ,isnull(pip.AssignDay16_30, 0) as AssignDay16_30
    ,isnull(pip.AssignDay31_45, 0) as AssignDay31_45
    ,isnull(pip.AssignDay46_70, 0) as AssignDay46_70
    ,isnull(pip.AssignDay71Plus, 0) as AssignDay71Plus
    ,isnull(pip.PayingClientCnt, 0) as PayingClientCnt
    ,isnull(cp.AmtNow, 0) as AmtNow
    ,isnull(cp.OtherNow, 0) as OtherNow
    ,isnull(cp.CntNow, 0) as CntNow
    ,isnull(cp.num1Now, 0) as num1Now
    ,isnull(cp.num2Now, 0) as num2Now
    ,isnull(cp.num3Now, 0) as num3Now
    ,isnull(cp.num4Now, 0) as num4Now
    ,isnull(cp.num5PlusNow, 0) as num5PlusNow
from sts.vw_admins a
left join PayInPeriod pip on pip.collectorid = a.id
left join CurrentPortfolio cp on cp.collectorid = a.id
where a.collectorGroups is not null
    or a.id in (select collectorid from CurrentPortfolio)
    or a.id in (select collectorid from PayInPeriod)
    