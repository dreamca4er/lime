set language russian
;

declare
    @dateFrom date = '20170501'
    ,@dateTo date = cast(getdate() as date)
;


drop table if exists #MonthTable
;

drop table if exists #opPaid
;

drop table if exists #npPaid
;

drop table if exists #paid
;

drop table if exists #l
;

drop table if exists #prdNum
;

with AllProducts as
(
    select
        op.ClientId
        ,op.ProductId
        ,op.Amount
        ,op.Period
        ,case when op.TariffId = 4 then 2 else 1 end as ProductType
        ,cast(op.DateStarted as date) as StartedOn
    from bi.OldProducts op
    where (op.DatePaid < '20180225' or op.DatePaid is null)
        and op.DateStarted < '20180225'
       
    union
   
    select
        p.clientId
        ,p.productid
        ,p.Amount
        ,p.Period
        ,p.ProductType
        ,cast(p.StartedOn as date)
    from prd.vw_product p
    where p.status > 2
)


select *
into #prdNum
from AllProducts ap
where cast(ap.StartedOn as date) >= @dateFrom
;

with l as
(
    select top ( isnull(nullif(datediff(m, @dateFrom, @dateTo), 0), 1))
        dateadd(m, datediff(m, 0, dateadd(m, row_number() over (order by name) - 1, @dateFrom)), 0) as MonthStart
    from sys.sysobjects
)

select
    cast(MonthStart as date) as MonthStart
    ,eomonth(MonthStart) as MonthEnd
    ,cast('20170501' as date) as M00
    ,cast('20170601' as date) as M0
    ,cast('20170701' as date) as M1
    ,cast('20170801' as date) as M2
    ,cast('20170901' as date) as M3
    ,cast('20171001' as date) as M4
    ,cast('20171101' as date) as M5
    ,cast('20171201' as date) as M6
    ,cast('20180101' as date) as M7
    ,cast('20180201' as date) as M8
    ,cast('20180301' as date) as M9
    ,cast('20180401' as date) as M10
    ,cast('20180501' as date) as M11
    ,cast('20180601' as date) as M12
into #l
from l
;

set @dateFrom = (select min(MonthStart) from #l)
;
set @dateTo = (select max(M0) from #l)
;

select
    l.MonthStart
    ,l.MonthEnd
    ,count(*) as ProductNumber
    ,sum(p.Amount) as TakenAmount
    ,l.M00
    ,l.M0
    ,l.M1
    ,l.M2
    ,l.M3
    ,l.M4
    ,l.M5
    ,l.M6
    ,l.M7
    ,l.M8
    ,l.M9
    ,l.M10
    ,l.M11
    ,l.M12
into #MonthTable
from #l l
inner join #prdNum p on p.StartedOn between l.MonthStart and l.MonthEnd
where p.ProductType = 2
group by
    l.MonthStart
    ,l.MonthEnd
    ,l.M00
    ,l.M0
    ,l.M1
    ,l.M2
    ,l.M3
    ,l.M4
    ,l.M5
    ,l.M6
    ,l.M7
    ,l.M8
    ,l.M9
    ,l.M10
    ,l.M11
    ,l.M12
;

select
    pn.ProductId
    ,dateadd(month, datediff(month, 0, pn.StartedOn), 0) as ProductStartedOn
    ,opp.DateCreated as PaymentDate
    ,opp.Amount as AmountPaid
    ,opp.Amount + opp.PercentAmount + opp.PenaltyAmount as TotalPaid
    ,pn.ProductType
into #opPaid
from bi.OldProductPayments opp
inner join #prdNum pn on pn.ProductId = opp.ProductId
where opp.DateCreated < '20180225'
;

select
    pn.ProductId
    ,dateadd(month, datediff(month, 0, pn.StartedOn), 0) as ProductStartedOn
    ,cb.DateOperation as PaymentDate
    ,cb.TotalAmount as AmountPaid
    ,cb.TotalAmount + cb.TotalPercent + cb.Fine as TotalPaid
    ,pn.ProductType
into #npPaid
from bi.CreditBalance cb
inner join #prdNum pn on pn.ProductId = cb.ProductId
where cb.DateOperation >= '20180225'
    and cb.InfoType = 'payment'
;

select *
into #paid
from
(
    select * from #opPaid
   
    union all
   
    select * from #npPaid
) p
;

select
    datepart(year, mt.MonthStart) as YearVal
    ,datename(month, mt.MonthStart) as MonthName
    ,mt.ProductNumber
    ,mt.TakenAmount
    -- Итого оплат по месяцам (нарастающий процент)
    ,sum(case when p.PaymentDate <= eomonth(mt.M00) then TotalPaid end) * 1.0 / mt.takenAmount as TotalPaidRunningPctM00
    ,sum(case when p.PaymentDate <= eomonth(mt.M0) then TotalPaid end) * 1.0 / mt.takenAmount as TotalPaidRunningPctM0
    ,sum(case when p.PaymentDate <= eomonth(mt.M1) then TotalPaid end) * 1.0 / mt.takenAmount as TotalPaidRunningPctM1
    ,sum(case when p.PaymentDate <= eomonth(mt.M2) then TotalPaid end) * 1.0 / mt.takenAmount as TotalPaidRunningPctM2
    ,sum(case when p.PaymentDate <= eomonth(mt.M3) then TotalPaid end) * 1.0 / mt.takenAmount as TotalPaidRunningPctM3
    ,sum(case when p.PaymentDate <= eomonth(mt.M4) then TotalPaid end) * 1.0 / mt.takenAmount as TotalPaidRunningPctM4
    ,sum(case when p.PaymentDate <= eomonth(mt.M5) then TotalPaid end) * 1.0 / mt.takenAmount as TotalPaidRunningPctM5
    ,sum(case when p.PaymentDate <= eomonth(mt.M6) then TotalPaid end) * 1.0 / mt.takenAmount as TotalPaidRunningPctM6
    ,sum(case when p.PaymentDate <= eomonth(mt.M7) then TotalPaid end) * 1.0 / mt.takenAmount as TotalPaidRunningPctM7
    ,sum(case when p.PaymentDate <= eomonth(mt.M8) then TotalPaid end) * 1.0 / mt.takenAmount as TotalPaidRunningPctM8
    ,sum(case when p.PaymentDate <= eomonth(mt.M9) then TotalPaid end) * 1.0 / mt.takenAmount as TotalPaidRunningPctM9
    ,sum(case when p.PaymentDate <= eomonth(mt.M10) then TotalPaid end) * 1.0 / mt.takenAmount as TotalPaidRunningPctM10
    ,sum(case when p.PaymentDate <= eomonth(mt.M11) then TotalPaid end) * 1.0 / mt.takenAmount as TotalPaidRunningPctM11
    ,sum(case when p.PaymentDate <= eomonth(mt.M12) then TotalPaid end) * 1.0 / mt.takenAmount as TotalPaidRunningPctM12
    -- Итого оплат по месяцам
    ,sum(case when cast(p.PaymentDate as date) between mt.M00 and eomonth(mt.M00) then TotalPaid end) as TotalPaidM00
    ,sum(case when cast(p.PaymentDate as date) between mt.M0 and eomonth(mt.M0) then TotalPaid end) as TotalPaidM0
    ,sum(case when cast(p.PaymentDate as date) between mt.M1 and eomonth(mt.M1) then TotalPaid end) as TotalPaidM1
    ,sum(case when cast(p.PaymentDate as date) between mt.M2 and eomonth(mt.M2) then TotalPaid end) as TotalPaidM2
    ,sum(case when cast(p.PaymentDate as date) between mt.M3 and eomonth(mt.M3) then TotalPaid end) as TotalPaidM3
    ,sum(case when cast(p.PaymentDate as date) between mt.M4 and eomonth(mt.M4) then TotalPaid end) as TotalPaidM4
    ,sum(case when cast(p.PaymentDate as date) between mt.M5 and eomonth(mt.M5) then TotalPaid end) as TotalPaidM5
    ,sum(case when cast(p.PaymentDate as date) between mt.M6 and eomonth(mt.M6) then TotalPaid end) as TotalPaidM6
    ,sum(case when cast(p.PaymentDate as date) between mt.M7 and eomonth(mt.M7) then TotalPaid end) as TotalPaidM7
    ,sum(case when cast(p.PaymentDate as date) between mt.M8 and eomonth(mt.M8) then TotalPaid end) as TotalPaidM8
    ,sum(case when cast(p.PaymentDate as date) between mt.M9 and eomonth(mt.M9) then TotalPaid end) as TotalPaidM9
    ,sum(case when cast(p.PaymentDate as date) between mt.M10 and eomonth(mt.M10) then TotalPaid end) as TotalPaidM10
    ,sum(case when cast(p.PaymentDate as date) between mt.M11 and eomonth(mt.M11) then TotalPaid end) as TotalPaidM11
    ,sum(case when cast(p.PaymentDate as date) between mt.M12 and eomonth(mt.M12) then TotalPaid end) as TotalPaidM12
    -- Оплат Тела по месяцам (нарастающий процент)
    ,sum(case when p.PaymentDate <= eomonth(mt.M00) then AmountPaid end) * 1.0 / mt.takenAmount as AmountPaidRunningPctM00
    ,sum(case when p.PaymentDate <= eomonth(mt.M0) then AmountPaid end) * 1.0 / mt.takenAmount as AmountPaidRunningPctM0
    ,sum(case when p.PaymentDate <= eomonth(mt.M1) then AmountPaid end) * 1.0 / mt.takenAmount as AmountPaidRunningPctM1
    ,sum(case when p.PaymentDate <= eomonth(mt.M2) then AmountPaid end) * 1.0 / mt.takenAmount as AmountPaidRunningPctM2
    ,sum(case when p.PaymentDate <= eomonth(mt.M3) then AmountPaid end) * 1.0 / mt.takenAmount as AmountPaidRunningPctM3
    ,sum(case when p.PaymentDate <= eomonth(mt.M4) then AmountPaid end) * 1.0 / mt.takenAmount as AmountPaidRunningPctM4
    ,sum(case when p.PaymentDate <= eomonth(mt.M5) then AmountPaid end) * 1.0 / mt.takenAmount as AmountPaidRunningPctM5
    ,sum(case when p.PaymentDate <= eomonth(mt.M6) then AmountPaid end) * 1.0 / mt.takenAmount as AmountPaidRunningPctM6
    ,sum(case when p.PaymentDate <= eomonth(mt.M7) then AmountPaid end) * 1.0 / mt.takenAmount as AmountPaidRunningPctM7
    ,sum(case when p.PaymentDate <= eomonth(mt.M8) then AmountPaid end) * 1.0 / mt.takenAmount as AmountPaidRunningPctM8
    ,sum(case when p.PaymentDate <= eomonth(mt.M9) then AmountPaid end) * 1.0 / mt.takenAmount as AmountPaidRunningPctM9
    ,sum(case when p.PaymentDate <= eomonth(mt.M10) then AmountPaid end) * 1.0 / mt.takenAmount as AmountPaidRunningPctM10
    ,sum(case when p.PaymentDate <= eomonth(mt.M11) then AmountPaid end) * 1.0 / mt.takenAmount as AmountPaidRunningPctM11
    ,sum(case when p.PaymentDate <= eomonth(mt.M12) then AmountPaid end) * 1.0 / mt.takenAmount as AmountPaidRunningPctM12
    -- Оплат Тела по месяцам
    ,sum(case when cast(p.PaymentDate as date) between mt.M00 and eomonth(mt.M00) then AmountPaid end) as AmountPaidM00
    ,sum(case when cast(p.PaymentDate as date) between mt.M0 and eomonth(mt.M0) then AmountPaid end) as AmountPaidM0
    ,sum(case when cast(p.PaymentDate as date) between mt.M1 and eomonth(mt.M1) then AmountPaid end) as AmountPaidM1
    ,sum(case when cast(p.PaymentDate as date) between mt.M2 and eomonth(mt.M2) then AmountPaid end) as AmountPaidM2
    ,sum(case when cast(p.PaymentDate as date) between mt.M3 and eomonth(mt.M3) then AmountPaid end) as AmountPaidM3
    ,sum(case when cast(p.PaymentDate as date) between mt.M4 and eomonth(mt.M4) then AmountPaid end) as AmountPaidM4
    ,sum(case when cast(p.PaymentDate as date) between mt.M5 and eomonth(mt.M5) then AmountPaid end) as AmountPaidM5
    ,sum(case when cast(p.PaymentDate as date) between mt.M6 and eomonth(mt.M6) then AmountPaid end) as AmountPaidM6
    ,sum(case when cast(p.PaymentDate as date) between mt.M7 and eomonth(mt.M7) then AmountPaid end) as AmountPaidM7
    ,sum(case when cast(p.PaymentDate as date) between mt.M8 and eomonth(mt.M8) then AmountPaid end) as AmountPaidM8
    ,sum(case when cast(p.PaymentDate as date) between mt.M9 and eomonth(mt.M9) then AmountPaid end) as AmountPaidM9
    ,sum(case when cast(p.PaymentDate as date) between mt.M10 and eomonth(mt.M10) then AmountPaid end) as AmountPaidM10
    ,sum(case when cast(p.PaymentDate as date) between mt.M11 and eomonth(mt.M11) then AmountPaid end) as AmountPaidM11
    ,sum(case when cast(p.PaymentDate as date) between mt.M12 and eomonth(mt.M12) then AmountPaid end) as AmountPaidM12
from #MonthTable mt
inner join #paid p on p.ProductStartedOn = mt.MonthStart
where p.ProductType = 2
group by
    datepart(year, mt.MonthStart)
    ,datename(month, mt.MonthStart)
    ,mt.MonthStart
    ,mt.ProductNumber
    ,mt.TakenAmount
order by mt.MonthStart