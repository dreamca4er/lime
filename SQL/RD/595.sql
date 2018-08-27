with op as 
(
    select
        cpd.OverdueDays
        ,count(case when cpd.AmountPaid = cpd.OverdueAmountDebt then 1 end) as AmountFullyPaidDay
        ,sum(count(case when cpd.AmountPaid = cpd.OverdueAmountDebt then 1 end)) over () as AmountFullyPaidTotal
    from bi.CollectorPortfolioDetail cpd
    inner join prd.LongTermCredit p on p.id = cpd.ProductId
    where cpd.OverdueAmountDebt > 0
    group by cpd.OverdueDays
)

select
    *
    ,AmountFullyPaidDay * 100.0 / AmountFullyPaidTotal as AmountFullyPaidPercent
    ,sum(AmountFullyPaidDay * 100.0 / AmountFullyPaidTotal) over (order by OverdueDays rows unbounded preceding) as AmountFullyPaidRunningPercent
from op
;


