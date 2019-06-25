select 
    p.ProductType
    , cast(StartedOn as date) as dt
    , count(*) as cnt
    , (count(*) - lag(count(*)) over (partition by p.ProductType order by cast(StartedOn as date))) * 100.0 / lag(count(*)) over (partition by p.ProductType order by cast(StartedOn as date)) as pct
from prd.vw_product p
where Status > 2
    and StartedOn >= '20190401'
group by cast(StartedOn as date), p.ProductType

select StatusName, p.PaymentWayName, p.ProductTypeName, cast(CreatedOn as date) as dt, count(*) as cnt
from prd.vw_product p
where CreatedOn >= '20190301'
group by p.PaymentWayName, ProductTypeName, StatusName, cast(CreatedOn as date)


select p.Productid, p.CreatedOn, BorrowPaymentId, PaymentWayName
from prd.vw_product p
where CreatedOn >= '20190301'
    and status = 2

select *
from pmt.Payment
where id in (3743268,3743328,3743421,3743490,3743644,3744352,3744419,3744575)
/
select *
from pmt.ContactPayment
where PaymentId = 61118735
/
select cast(CreatedOn as date), count(*)
from client.UserLongTermTariff
where CreatedOn >= '20190401'
group by cast(CreatedOn as date)

select cast(CreatedOn as date), count(*)
from client.UserShortTermTariff
where CreatedOn >= '20190401'
group by cast(CreatedOn as date)

select cast(ModifiedOn as date), count(*)
from client.UserLongTermTariff
where ModifiedOn >= '20190301'
    and IsLatest = 0
group by cast(ModifiedOn as date)

select cast(ModifiedOn as date), count(*)
from client.UserShortTermTariff
where ModifiedOn >= '20190301'
    and IsLatest = 0
group by cast(ModifiedOn as date)

select *
from prd.LongTermTariff

select *
from bi.tf_gendate('20190301', '20190430') d
outer apply
(
    select count(*) as STCount
    from client.UserShortTermTariff ut
    where ut.CreatedOn < d.dt2
        and (ut.ModifiedOn is null or ut.ModifiedOn > d.dt2)
) st
outer apply
(
    select count(*) as LTCount
    from client.UserLongTermTariff ut
    where ut.CreatedOn < d.dt2
        and (ut.ModifiedOn is null or ut.ModifiedOn > d.dt2)
) lt

/
with Activated as 
(
    select
        p.StartedOn as Date
        , count(*) as LongTermIssuedCount
        , sum(p.Amount) as LongTermIssuedSum
    from prd.vw_Product p
    where p.ProductType = 2
        and p.Status > 2
        and p.StartedOn >= '20190420'
        and p.StartedOn < '20190430'
    group by p.StartedOn
)

,Repaid as 
(
    select
        cast(p.DatePaid as Date) as Date
        , count(*) as LongTermPaidCount
        , sum(pay.TotalPaid) as LongTermPaidSum
    from prd.vw_Product p
    outer apply
    (
        select sum(cb.TotalDebt) as TotalPaid 
        from bi.CreditBalance cb
        where cb.ProductId = p.Productid
            and cb.InfoType = 'payment'
            and cast(cb.DateOperation as date) >= '20190420'
    ) pay
    where p.ProductType = 2
        and p.Status = 5
        and cast(p.DatePaid as Date) >= '20190420'
    group by cast(p.DatePaid as Date)
)

select
    a.*
    , r.LongTermPaidCount
    , r.LongTermPaidSum
from Activated a
inner join Repaid r on a.Date = r.Date
/

select
    p.Productid
    , sl.StartedOn as OverdueStart
    , p.StatusName as CurrentStatus
    , jss.*
from prd.vw_statusLog sl
inner join prd.vw_product p on p.productid = sl.ProductId
    and p.ProductType = 2
    and sl.Status = 4
outer apply
(
    select top 1 lts.ScheduleSnapshot
    from prd.LongTermSchedule lts
    inner join prd.LongTermScheduleLog ltsl on ltsl.ScheduleId = lts.Id
    where lts.ProductId = p.Productid
        and ltsl.StartedOn < sl.StartedOn
    order by ltsl.StartedOn desc 
) ss
outer apply
(
    select top 1
        jss.ScheduledAmount
        , jss.ScheduledPercent
    from openjson(ss.ScheduleSnapshot) with
    (
        Date date '$.Date'
        , ScheduledAmount numeric(18, 2) '$.Amount'
        , ScheduledPercent numeric(18, 2) '$.Percent'
    ) jss
    where jss.Date <= sl.StartedOn
    order by jss.Date desc 
) jss
where sl.StartedOn >= '20190427'


select
    p.Productid
    , ps.PrevStatus
    , sl.StartedOn as RestructStart
    , debt.RestructuredDebt
from prd.vw_statusLog sl
outer apply
(
    select top 1 slp.StatusName as PrevStatus
    from prd.vw_statusLog slp
    where slp.ProductId = sl.ProductId
        and slp.StartedOn < sl.StartedOn
    order by slp.StartedOn desc
) ps
inner join prd.vw_product p on p.productid = sl.ProductId
    and p.ProductType = 2
    and sl.Status = 7
outer apply
(
    select top 1 (cb.TotalAmount + cb.TotalPercent) * -1 as RestructuredDebt
    from bi.CreditBalance cb
    where cb.InfoType = 'debt'
        and cb.ProductId = sl.ProductId
        and cb.DateOperation < sl.StartedOn
    order by cb.DateOperation desc 
) debt
where sl.StartedOn >= '20190427'