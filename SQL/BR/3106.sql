with cd as 
(
    select
        cpd.CollectorId
        ,cpd.Date
        ,min(cpd.OverdueDays) as MinOverdueDays
        ,sum(cpd.TotalDebt) as Portfolio
        ,sum(cpd.TotalPaid) as TotalPaid
        ,sum(cpd.AmountPaid) as AmountPaid
    from bi.CollectorPortfolioDetail cpd
    group by 
        cpd.CollectorId
        ,cpd.Date
)

,gr as 
(
    select
        cast(format(dt.Date, 'yyyyMM01') as date) as Mnth
        ,dt.Date
        ,dt.CollectorId
        ,case
            when u.UserName = 'FakeCollectorPS' then 'D'
            when u.UserName like 'FakeCollector%' then cg.name
            when dt.MinOverdueDays >= 75 and dt.Date >= '20180903' then 'D'
            when dt.MinOverdueDays >= 46 then 'C'
            else 'B'
        end as CollectorGroup
        ,u.name as CollectorName
        ,u.Is_Enabled
    from cd dt
    left join sts.vw_admins u on u.id = dt.CollectorId
    left join col.CollectorGroup cg on cg.CollectorId = dt.CollectorId
)

select *
into #cg
from gr
/
,cm as 
(
    select distinct
        Mnth
        ,CollectorId
        ,CollectorName
        ,first_value(CollectorGroup) over (partition by CollectorId, Mnth order by Date desc) as CollectorGroup
    from gr
)
    
select
    gd.dt1 as Date
    ,cm.CollectorId
    ,cm.CollectorName
    ,cm.CollectorGroup
    ,cgm.GroupName as CollectorGroupName
    ,min(gr.Is_Enabled) over (partition by cm.CollectorId) as Is_Enabled
    ,case when cm.CollectorGroup != 'B' then 1 else 0 end as IncludePaidAmount
    ,gr.CollectorGroup as DayCollectorGroup
    ,cg.GroupName as DayCollectorGroupName
from cm
outer apply
(
    select dt1
    from bi.tf_gendate(cm.Mnth, eomonth(cm.Mnth))
) gd
left join gr on gr.Date = gd.dt1
    and gr.CollectorId = cm.CollectorId
left join col.vw_cg cgm on cgm.GroupId = cm.CollectorGroup
left join col.vw_cg cg on cg.GroupId = gr.CollectorGroup
where gd.dt1 <= cast(getdate() as date)

/

select
    cpd.ClientId
    ,cpd.ProductId
    ,cpd.Date
    ,prev.CollectorName
    ,cb.PaidSum
from bi.CollectorPortfolioDetail cpd
inner join #cg cg on cg.CollectorId = cpd.CollectorId
    and cg.Date = cpd.Date
cross apply 
(
    select cg2.CollectorName
    from bi.CollectorPortfolioDetail cpd2
    inner join #cg cg2 on cg2.CollectorId = cpd2.CollectorId
        and cg2.Date = cpd2.Date
    where cpd2.ProductId = cpd.ProductId
        and cpd2.Date = dateadd(d, -1, cpd.Date)
        and cg2.CollectorGroup = 'C'
) prev
outer apply
(
    select 
        sum(cb.TotalDebt) as PaidSum
    from bi.CreditBalance cb
    where cb.ProductId = cpd.ProductId
        and cb.InfoType = 'payment'
        and cast(cb.DateOperation as date) between cpd.Date and dateadd(d, 6, cpd.Date)
) cb
where cpd.Date between '20180801' and '20180831'
    and cg.CollectorGroup = 'D'
