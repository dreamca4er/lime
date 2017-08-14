/*
declare 
    @d1 date = '20170601'
    ,@d2 date = '20170701'
    ,@creditNumberFrom int = null
    ,@creditNumberTo int = null;
*/

select
    c.id as creditid
    ,row_number() over (partition by c.userid order by c.id) as rn
into #credNum
from dbo.Credits c
where c.status not in (5, 8);

select
    min(dch.id) as collectorAssignId
    ,dch.DateCreated as collectorDate
    ,dch.debtorid
    ,d.creditId
    ,c.userId
    ,dch.CollectorId
    ,c.DatePaid
into #collectorAssign
from dbo.DebtorCollectorHistory dch
inner join dbo.Debtors d on d.Id = dch.DebtorId
inner join dbo.Credits c on c.Id = d.CreditId
where dch.DateCreated >= @d1
    and (c.DatePaid is null or c.DatePaid > dch.DateCreated)
group by 
    dch.DateCreated
    ,d.creditId
    ,dch.debtorid
    ,c.userId
    ,c.DatePaid
    ,dch.CollectorId;

with collectorAssign as 
(
    select 
        ca.*
        ,cn.rn
    from #collectorAssign ca
    inner join #credNum cn on cn.creditid = ca.CreditId
        and (cn.rn >= @creditNumberFrom or @creditNumberFrom is null)
        and (cn.rn <= @creditNumberTo or @creditNumberTo is null)
)

,collectorFirstAssign as 
(
    select
        ca.creditId
        ,ca.CollectorId
        ,min(ca.collectorDate) as firstCollectorAssign
    from collectorAssign ca
    group by 
        ca.creditId
        ,ca.CollectorId
)

,collectorStartEnd as 
(
    select distinct
        ca1.collectorAssignId
        ,ca1.creditId
        ,ca1.DatePaid
        ,ca1.userId
        ,ca1.CollectorId
        ,ca1.debtorid
        ,ca1.collectorDate as collectorStart
        ,ca2.collectorDate as collectorEnd
        ,cb.Amount as AmountDebt
        ,cb.PercentAmount
        + cb.CommisionAmount
        + cb.PenaltyAmount
        + cb.LongPrice
        + cb.TransactionCosts as otherDebt
    from collectorAssign ca1
    left join collectorAssign ca2 on ca1.creditId = ca2.creditId
        and ca2.collectorDate =
            (
                select min(ca3.collectorDate)
                from collectorAssign ca3
                where ca3.creditId = ca1.creditId
                    and ca3.collectorDate > ca1.collectorDate
            )
    left join dbo.CreditBalances cb on cb.CreditId = ca1.creditId
        and cb.date = dateadd(d, -1, cast(ca1.collectorDate as date))
    where cast(ca1.collectorDate as date) <= @d2
)

,lastCreditBalance as
(
    select distinct
        cse.collectorAssignId
        ,cse.collectorStart
        ,cse.collectorEnd
        ,cse.DatePaid
        ,cse.creditId
        ,cse.CollectorId
        ,cb.Amount as AmountDebt
        ,cb.PercentAmount
        + cb.CommisionAmount
        + cb.PenaltyAmount
        + cb.LongPrice
        + cb.TransactionCosts as otherDebt
    from collectorStartEnd cse
    left join dbo.CreditBalances cb on cb.CreditId = cse.creditId
        and cb.date = (select max(cb2.date)
                       from dbo.CreditBalances cb2
                       where cb2.amount != 0
                           and cb2.CreditId = cb.CreditId
                           and cb2.date <= 
                       dateadd(d, -1,
                       cast(
                       (
                           select min(dt)
                           from
                           (
                               select cse.collectorEnd as dt union
                               select cse.DatePaid union
                               select getdate()
                           ) a
                       ) as date)
                       ))
)

,neededAmountDebtValue as 
(
    select
        cse.CollectorId
--        ,cse.creditId
        ,sum(cse.AmountDebt) as AmountDebt
    from collectorStartEnd cse
    inner join collectorFirstAssign cfa on cfa.creditId = cse.creditId
        and cse.CollectorId = cfa.CollectorId
        and cse.collectorStart = cfa.firstCollectorAssign
    group by cse.CollectorId
)

,neededPercentDebtValue as 
(
    select
        lcb.CollectorId
--        ,lcb.creditId
        ,sum(lcb.otherDebt) as otherDebt
    from lastCreditbalance lcb
    group by
        lcb.CollectorId
--        ,lcb.creditId
)

,pays as 
(
    select
        cp.id as paymentId
        ,cp.creditid
        ,cp.DateCreated as paymentDate
        ,cp.Amount as amountPaid
        ,cp.PercentAmount 
        + cp.CommissionAmount 
        + cp.PenaltyAmount 
        + cp.LongPrice 
        + cp.TransactionCosts as otherPaid
        ,cse.collectorid
        ,cse.collectorstart
        ,cse.collectorend
    from dbo.CreditPayments cp
    inner join dbo.Payments p on p.Id = cp.PaymentId
        and p.Way != 6
    inner join collectorStartEnd cse on cse.creditid = cp.creditid
        and cp.DateCreated >= cse.collectorStart
        and (cp.DateCreated < cse.collectorEnd or cse.collectorEnd is null)
        and cast(cp.DateCreated as date) <= dateadd(d, 30, cse.collectorStart)
    where cp.creditid in (select creditid from collectorStartEnd)
      and (
            @withActivity = 1
                and exists (select 1 from dbo.DebtorInteractionHistory dih
                            where dih.DebtorId = cse.debtorid
                                and dateadd(hh, 3, dih.TimestampUtc) < cp.DateCreated)
            or @withActivity = 0
          )
)

,neededPays as 
(
    select
        collectorid
        ,sum(amountPaid) as amountPaid
        ,sum(otherPaid) as otherPaid
    from pays
    group by collectorid
)

select
    nadv.collectorid
    ,u.username
    ,nadv.AmountDebt
    ,npdv.otherDebt
    ,isnull(np.amountPaid, 0) as amountPaid
    ,isnull(np.otherPaid, 0) as otherPaid
from neededAmountDebtValue nadv
left join neededPercentDebtValue npdv on npdv.collectorid = nadv.collectorid
left join neededPays np on np.collectorid =  nadv.collectorid
left join CmsContent_LimeZaim.dbo.users u on u.userid = nadv.collectorid
where u.userid in (@collector)
order by u.username

drop table #credNum;
drop table #collectorAssign;