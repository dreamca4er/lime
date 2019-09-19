drop table if exists #op
;

select
    op.ProductId
    , op.AssignDate as M0
    , dateadd(month, 1, op.AssignDate) as M1
    , dateadd(month, 2, op.AssignDate) as M2 
    , dateadd(month, 3, op.AssignDate) as M3 
    , dateadd(month, 4, op.AssignDate) as M4 
    , dateadd(month, 5, op.AssignDate) as M5 
    , dateadd(month, 6, op.AssignDate) as M6 
    , dateadd(month, 7, op.AssignDate) as M7 
    , dateadd(month, 8, op.AssignDate) as M8 
    , dateadd(month, 9, op.AssignDate) as M9
    , dateadd(month, 10, op.AssignDate) as M10
into #op
from col.tf_op('20180101', '20190801') op
where op.CollectorGroupId = 6
;


select
    dateadd(month, datediff(month, 0, op.M0), 0) as AssignMonth
    , sum(case when cb.DateOperation >= op.M0 and cb.DateOperation < op.M1 then cb.TotalDebt - TotalAmount end) as M0
    , sum(case when cb.DateOperation >= op.M0 and cb.DateOperation < op.M2 then cb.TotalDebt - TotalAmount end) as M1
    , sum(case when cb.DateOperation >= op.M0 and cb.DateOperation < op.M3 then cb.TotalDebt - TotalAmount end) as M2
    , sum(case when cb.DateOperation >= op.M0 and cb.DateOperation < op.M4 then cb.TotalDebt - TotalAmount end) as M3
    , sum(case when cb.DateOperation >= op.M0 and cb.DateOperation < op.M5 then cb.TotalDebt - TotalAmount end) as M4
    , sum(case when cb.DateOperation >= op.M0 and cb.DateOperation < op.M6 then cb.TotalDebt - TotalAmount end) as M5
    , sum(case when cb.DateOperation >= op.M0 and cb.DateOperation < op.M7 then cb.TotalDebt - TotalAmount end) as M6
    , sum(case when cb.DateOperation >= op.M0 and cb.DateOperation < op.M8 then cb.TotalDebt - TotalAmount end) as M7
    , sum(case when cb.DateOperation >= op.M0 and cb.DateOperation < op.M9 then cb.TotalDebt - TotalAmount end) as M8
    , sum(case when cb.DateOperation >= op.M0 and cb.DateOperation < op.M10 then cb.TotalDebt - TotalAmount end) as M9
from #op op
inner join bi.CreditBalance cb on cb.ProductId = op.ProductId
    and cb.InfoType = 'payment'
    and cb.DateOperation >= op.M0
--    and cb.ProductId = 48840
group by dateadd(month, datediff(month, 0, op.M0), 0)
/
with d as 
(
    select
        Date
        , pd.Groupid
        , cg.GroupName
        , sum(pd.OverdueAmountDebt) * -1 as AmountDebt
        , sum(pd.OverduePercentDebt + pd.FineDebt + pd.CommissionDebt) * -1 as OtherDebt
    from bi.CollectorPortfolioDetail pd
    inner join col.vw_cg cg on cg.GroupId = pd.GroupId
    where Date = eomonth(Date)
    group by Date, pd.Groupid, cg.GroupName
)

select
    format(Date, 'yyyy_MM_dd') as "Месяц прироста просрочки"
    , GroupId
    , GroupName as "Группа"
    , AmountDebt - nullif(lag(AmountDebt) over (partition by Groupid order by Date), 0) as "Прирост просрочки по телу"
    , OtherDebt - nullif(lag(OtherDebt) over (partition by Groupid order by Date), 0) as "Прирост прочей просрочки"
from d
