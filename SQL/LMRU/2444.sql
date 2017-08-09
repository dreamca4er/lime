--declare @cred int = 37819;

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

select
  dateadd(d, rn, '20170601') as dt
into #dates
from cj
where dateadd(d, rn, '20170601') < '20170701'


select distinct
  cast(dch.DateCreated as date) as collectorDate,
  d.Id as debtorId,
  fu.Id as userId,
  fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio,
  c.id as creditId,
  c.Period,
  cast(c.DateCreated as date) as creditStarted,
  cast(dateadd(d, c.Period, c.DateCreated) as date) as creditFinalPre
into #cte_creditsPre
from dbo.DebtorCollectorHistory dch
join dbo.Debtors d on d.Id = dch.DebtorId
join dbo.Credits c on c.Id = d.CreditId
join dbo.FrontendUsers fu on fu.Id = c.UserId
where CollectorId in (select UserId
                      from CmsContent_LimeZaim.dbo.UserGroupLinks
                      where UserGroupId = 44)
    and dch.DateCreated >= '20170601'
    and dch.DateCreated < '20170701'


select
    csh.id
    ,csh.CreditId
    ,csh.Status
    ,cast(csh.DateStarted as date) statusStart
    ,row_number() over (partition by csh.CreditId order by csh.DateStarted) as rn
into #cs
from dbo.CreditStatusHistory csh
where csh.CreditId in (select creditId from #cte_creditsPre)
;

with nextStatusPre as
(
    select *
    from #cs cs
    where exists (select 1 from #cs cs1
                  where cs1.CreditId = cs.CreditId
                     and cs1.rn = cs.rn - 1
                     and cs1.Status != cs.status)
      or cs.rn = 1
)

select
    nsp.*
    ,cast(nextStatus.statusStart as date) as statusEnd
into #creditStatuses
from nextStatusPre nsp
outer apply 
(
    select min(nsp1.id) as id
    from nextStatusPre nsp1
    where nsp1.CreditId = nsp.CreditId
        and nsp1.id > nsp.id
) nsp1
left join nextStatusPre nextStatus on nextStatus.id = nsp1.id
;

with debt as 
(
    select
        cs.creditid
        ,cp.debtorid
        ,cp.userid
        ,cs.statusStart as overdueStart
        ,cs.statusEnd as overdueEnd
        ,cp.collectorDate
        ,cb.Amount as amountDebt
        ,cb.PercentAmount + cb.CommisionAmount + cb.PenaltyAmount + cb.LongPrice + cb.TransactionCosts as otherDebt
    from #creditStatuses cs
    inner join #cte_creditsPre cp on cp.CreditId = cs.CreditId
        and datediff(d, cs.statusStart, cp.collectorDate) + 1 = 4
        and (cs.statusEnd is null or statusEnd >= cp.collectorDate)
    left join dbo.CreditBalances cb on cb.CreditId = cp.creditid
        and cb.Date = dateadd(d, -1, cp.collectorDate)
    where cs.status = 3
--        and cs.creditid = @cred
)

,pays as 
(
    select
        cp.CreditId
        ,cast(cp.DateCreated as date) as paymentDate
        ,cp.Amount as amountPaid
        ,cp.PercentAmount
        ,cp.PercentAmount + cp.CommissionAmount + cp.PenaltyAmount + cp.LongPrice + cp.TransactionCosts as otherPaid
        ,row_number() over (partition by cp.CreditId order by cp.id desc) as rn
    from dbo.CreditPayments cp
    inner join dbo.Payments p on p.Id = cp.PaymentId
        and p.Way != 6
    where exists 
        (
            select 1 from debt
            where debt.CreditId = cp.CreditId
                and cp.DateCreated >= debt.collectorDate
        )
        and cp.DateCreated >= '20170601'
        and cp.DateCreated < '20170701'
)

,debtAgg as 
(
    select
        dates.dt
        ,isnull(sum(debt.amountDebt), 0) as amountDebt
        ,isnull(sum(debt.otherDebt), 0) as otherDebt
    from #dates dates
    left join debt on dates.dt = debt.collectorDate
--        and creditid = @cred
    group by dates.dt
)

,paymentsAgg as 
(
    select
        d.dt
        ,isnull(sum(p.amountPaid), 0) as amountPaid
        ,isnull(sum(p.otherPaid), 0) as otherPaid
    from #dates d
    left join pays p on p.paymentDate = d.dt
        and exists (select 1 from debt
                    where debt.creditid = p.creditid
                        and debt.collectordate <= p.paymentDate)
--       and creditid = @cred
    group by dt
)


select
    da.dt as "Дата"
    ,da.amountDebt as "Долг по телу"
    ,da.otherDebt as "Прочий долг"
    ,da.amountDebt + da.otherDebt as "Всего долг"
    ,pa.amountPaid as "Оплаты по телу"
    ,pa.otherPaid as "Прочие оплаты"
    ,pa.amountPaid + pa.otherPaid as "Всего оплат"
from debtAgg da
left join paymentsAgg pa on pa.dt = da.dt

union

select 
    null
    ,ad.amountDebt
    ,sum(cb.PercentAmount + cb.CommisionAmount + cb.PenaltyAmount + cb.LongPrice + cb.TransactionCosts) 
    + sum(pay.percentPayments) as otherDebt
    ,ad.amountDebt
    + isnull(sum(cb.PercentAmount + cb.CommisionAmount + cb.PenaltyAmount + cb.LongPrice + cb.TransactionCosts), 0)
    + sum(pay.percentPayments) as allDebt
    ,null
    ,null
    ,null
from (select sum(amountDebt) as amountDebt from debt) ad, dbo.CreditBalances cb
outer apply 
(
    select isnull(sum(p.PercentAmount), 0) as percentPayments
    from pays p
    inner join dbo.Credits c on c.Id = p.CreditId
    where p.creditid = cb.creditid
        and p.paymentDate >= (select min(d1.collectordate) 
                              from debt d1
                              where d1.creditid = p.creditid)
        and p.rn != case when c.DatePaid < '20170701' then 1 else 0 end
    
) pay
where cb.CreditId in (select creditid from debt/* where debt.creditid = @cred*/)
    and cb.id = (select max(cb1.id)
                   from dbo.CreditBalances cb1
                   where cb1.CreditId = cb.CreditId
                       and cb1.date < '20170701'
                       and cb1.Amount 
                           + cb1.PercentAmount 
                           + cb1.CommisionAmount 
                           + cb1.PenaltyAmount 
                           + cb1.LongPrice 
                           + cb1.TransactionCosts > 0)
group by ad.amountDebt
order by "Дата"

drop table #creditStatuses
drop table #cs
drop table #cte_creditsPre
drop table #dates

