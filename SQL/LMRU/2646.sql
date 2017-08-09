-- 1. Берем должников, переданных в июне
-- 2. Берем их просрочки за определенный период
-- 3. Берем должников из п1 только тогда, когда они 4ый день в просрочке на дату передачи их коллекторам
-- 4. Берем платежи (1.07 - 29.07) по должникам по след. принципу: 
--1 июля: платежи в эту дату по суммам, поступившим в обработку коллекторов Г1 в интервале со 2.06 по 30.06
--2 июля: платежи в эту дату по суммам, поступившим в обработку коллекторов Г1 в интервале со 3.06 по 30.06
--...
--29 июля: платежи в эту дату по суммам, поступившим в обработку коллекторов Г1 30.06

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
        ,min(collectorDate) over (partition by cs.creditid) as firstCollectorDate
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
        ,cp.DateCreated as paymentDateTime
        ,cp.Amount as amountPaid
        ,cp.PercentAmount as PercentAmountPaid
        ,cp.CommissionAmount as CommissionAmountPaid
        ,cp.PenaltyAmount as PenaltyAmountPaid
        ,cp.LongPrice as LongPricePaid
        ,cp.TransactionCosts as TransactionCostsPaid
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
        and cp.DateCreated < '20170801'
)

,interactions as 
(
    select 
        c.UserId
        ,d.CreditId
        ,dateadd(hh, 3, dih.TimestampUtc) as interDateTime
    from dbo.DebtorInteractionHistory dih
    join Debtors d on d.id = dih.DebtorId
    join Credits c on c.Id = d.CreditId
    where exists (select 1 from debt
                  where debt.creditid = c.id
                    and dateadd(hh, 3, dih.TimestampUtc) >= debt.collectorDate)
)

,paysTail as 
(
    select
        p.paymentDate as "Дата"
        ,sum(p.amountPaid) as "Тело оплачено"
        ,sum(p.PercentAmountPaid) as "Проценты оплачены"
        ,sum(p.CommissionAmountPaid) as "Комиссия оплачена"
        ,sum(p.PenaltyAmountPaid) as "Штрафы оплачены"
        ,sum(p.LongPricePaid) as "Продления оплачены"
        ,sum(p.TransactionCostsPaid) as "Транз. издержки оплачены"
    from pays p
    where p.paymentDate >= '20170701'
        and p.paymentDate < '20170730'
        and exists (select 1 from debt d
                    where d.creditid = p.creditid
                        and d.collectordate >= dateadd(d, -29, paymentDate)
                        and d.collectordate <= '20170630')
        and exists (select 1 from interactions i
                    where i.CreditId = p.CreditId
                        and i.interDateTime < p.paymentDateTime)
        and exists (select 1 from debt d
                    where d.creditid = p.creditid
                        and p.paymentDate between d.collectordate and dateadd(d, 45, d.collectordate))
    group by p.paymentDate
)

,paysJune as 
(
    select
        p.paymentDate as "Дата"
        ,sum(p.amountPaid) as "Тело оплачено"
        ,sum(p.PercentAmountPaid) as "Проценты оплачены"
        ,sum(p.CommissionAmountPaid) as "Комиссия оплачена"
        ,sum(p.PenaltyAmountPaid) as "Штрафы оплачены"
        ,sum(p.LongPricePaid) as "Продления оплачены"
        ,sum(p.TransactionCostsPaid) as "Транз. издержки оплачены"
    from pays p
    where exists (select 1 from debt
                  where debt.creditid = p.creditid
                      and debt.collectordate <= p.paymentDate)
        and p.paymentDate >= '20170601'
        and p.paymentDate < '20170701'
        and exists (select 1 from interactions i
                    where i.CreditId = p.CreditId
                        and i.interDateTime < p.paymentDateTime)
        and exists (select 1 from debt d
                    where d.creditid = p.creditid
                        and p.paymentDate between d.collectordate and dateadd(d, 45, d.collectordate))     
    group by p.paymentDate
)


select * from paysJune
union
select * from paysTail

drop table #creditStatuses
drop table #cs
drop table #cte_creditsPre
drop table #dates
