with nums as (
select 1 as a union all
select 1 as a union all
select 1 as a union all
select 1 as a union all
select 1 as a union all
select 1 as a union all
select 1 as a union all
select 1 as a union all
select 1 as a union all
select 1 as a 
)

,cj as (
select
  row_number() over (order by n1.a) - 1 as rn
from nums n1
cross join nums n2
)

,dates as (
select
  dateadd(d, rn, '20170601') as dt
from cj
where dateadd(d, rn, '20170601') <= '20170714'
)

 ,cte_credits as (
select
  d.Id as debtorId,
  fu.Id as userId,
  fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio,
  c.id as creditId,
  c.Period,
  cast(c.DateCreated as date) as creditStarted,
  cast(dateadd(d, c.Period, c.DateCreated) as date) as creditFinalPre,
  cast(csh.DateStarted as date) as creditFinished
from DebtorCollectorHistory dch
join Debtors d on d.Id = dch.DebtorId
join Credits c on c.Id = d.CreditId
join FrontendUsers fu on fu.Id = c.UserId
left join CreditStatusHistory csh on csh.CreditId = c.id
  and csh.Status = 2
where dch.IsLatest = 1
  and CollectorId in (select UserId
                      from CmsContent_LimeZaim.dbo.UserGroupLinks
                      where UserGroupId = 44)
  and (csh.DateStarted is null or csh.DateStarted >= '20170601')
)

,cte_Statuses as (
select
  csh.CreditId,
  cast(csh.DateStarted as date) as overdueStarted,
  cast(csh_next.DateStarted as date) as overdueFinished
from CreditStatusHistory csh
left join CreditStatusHistory csh_next on csh_next.CreditId = csh.CreditId
  and csh_next.id > csh.id
  and csh_next.Id = (select min(csh_next1.id)
                     from CreditStatusHistory csh_next1
                     where csh_next1.CreditId = csh_next.CreditId
                       and csh_next1.status != 3
                       and csh_next1.id > csh.id)
where csh.CreditId in (select creditId from cte_credits)
  and csh.DateStarted > dateadd(d, -4, '20170601')
  and csh.Status = 3
)

,cte_creditsStatuses as (
select
  c.*,
  s.overdueStarted,
  s.overdueFinished
from cte_credits c
join cte_Statuses s on s.creditid = c.creditid
)

,overdue as (
select 
  *, 
  datediff(d, cs.overdueStarted, d.dt) + 1 as overdueDays
from dates d
left join cte_creditsStatuses cs on datediff(d, cs.overdueStarted, d.dt) + 1 >= 4 + case when d.dt >= '20170701' then datediff(d, '20170701', d.dt) + 1 else 0 end
  and datediff(d, cs.overdueStarted, d.dt) + 1 <= (4 + datediff(d, '20170601', d.dt))
  and (overdueFinished is null or overdueFinished >= d.dt)
)

,payments as (
select
  CreditId,
  cast(DateCreated as date) as date,
  sum(Amount) as AmountPayed,
  sum(PercentAmount) as PercentAmountpayed,
  sum(CommissionAmount) as CommissionAmountpayed,
  sum(PenaltyAmount) as PenaltyAmountPayed,
  sum(LongPrice) as LongPricePayed,
  sum(TransactionCosts) as TransactionCostsPayed
from CreditPayments cp
where CreditId in (select creditId from cte_credits)
group by 
  CreditId,
  cast(DateCreated as date)
)

,preFin as (
select 
  o.*,
  isnull(cb.Amount, 0) as amountDebt,
  isnull(cb.PercentAmount, 0) as PercentAmountDebt,
  isnull(cb.CommisionAmount, 0) as CommisionAmountDebt,
  isnull(cb.PenaltyAmount, 0) as PenaltyAmountDebt,
  isnull(cb.LongPrice, 0) as LongPriceDebt,
  isnull(cb.TransactionCosts, 0) as TransactionCostsDebt,
  isnull(p.AmountPayed, 0) as AmountPayed,
  isnull(p.PercentAmountpayed, 0) as PercentAmountpayed,
  isnull(p.CommissionAmountpayed, 0) as CommissionAmountpayed,
  isnull(p.PenaltyAmountPayed, 0) as PenaltyAmountPayed,
  isnull(p.LongPricePayed, 0) as LongPricePayed,
  isnull(p.TransactionCostsPayed, 0) as TransactionCostsPayed
from overdue o
left join CreditBalances cb on cb.creditid = o.creditid
  and o.dt = datediff(d, -1, cb.date)
  and o.overdueDays = case when o.dt < '20170701' then 4
                           else datediff(d, '20170701', o.dt) + 5
                      end
left join payments p on p.CreditId = o.CreditId
  and p.date = o.dt
)

select
  dt,
  debtorId,
  userId,
  fio,
  creditId,
  Period,
  creditStarted,
  creditFinalPre,
  creditFinished,
  overdueStarted,
  overdueFinished,
  overdueDays,
  amountDebt as bodyDebt,
  PercentAmountDebt + CommisionAmountDebt + PenaltyAmountDebt + LongPriceDebt + TransactionCostsDebt as otherDebt,
  AmountPayed as bodyPaid,
  PercentAmountpayed + CommissionAmountpayed + PenaltyAmountPayed + LongPricePayed + TransactionCostsPayed as otherPaid
from preFin