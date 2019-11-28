declare @dateFrom date = '20190701'
;

drop table if exists #main
;

with a as 
(
    select
        cast(psc.BusinessDate as date)  as Date
        , sum(sum(iif(st.SumType = 'ActiveSt', psc.Sum, 0))) 
            over (order by cast(psc.BusinessDate as date) rows unbounded preceding) as st
        , sum(sum(iif(st.SumType = 'ActiveSt' and p.PercentPerDay = 0, psc.Sum, 0))) 
            over (order by cast(psc.BusinessDate as date) rows unbounded preceding) as stZero
        , sum(sum(iif(st.SumType = 'ActiveLt', psc.Sum, 0))) 
            over (order by cast(psc.BusinessDate as date) rows unbounded preceding) as lt
        , sum(sum(iif(st.SumType = 'OverdueSt', psc.Sum, 0))) 
            over (order by cast(psc.BusinessDate as date) rows unbounded preceding) as stOp
        , sum(sum(iif(st.SumType = 'OverdueLt', psc.Sum, 0))) 
            over (order by cast(psc.BusinessDate as date) rows unbounded preceding) as ltOp
    
        , sum(iif(psc.ProductType = 1 and psc.State = 2 and psc.ChangeType in (1, 9), psc.RawSum, 0)) as StIssuedLoan
        , sum(iif(st.SumType = 'ActiveSt' and ad.Number like '%2' and psc.ChangeType = 6 and Sum < 0, Sum, 0)) as StActiveToOverdue
        , sum(iif(st.SumType = 'OverdueSt' and psc.ChangeType = 6 and Sum < 0, -Sum, 0)) as StOverdueToRest
        , sum(iif(st.SumType = 'ActiveSt' and psc.ChangeType = 4, psc.Sum, 0)) as StPaidActive
        , sum(iif(po.OperationTemplateId in (7,17,25,26) and st.SumType = 'ActiveSt' and psc.ChangeType = 4, psc.Sum, 0)) as StPaidActiveAoS
        , sum(iif(st.SumType = 'OverdueSt' and psc.ChangeType = 4, psc.Sum, 0)) as StPaidOverdue
        
        , sum(iif(psc.ProductType = 2 and psc.State = 2 and psc.ChangeType in (1, 9), psc.RawSum, 0)) as LtIssuedLoan
        , sum(iif(st.SumType = 'ActiveLt' and ad.Number like '%2' and psc.ChangeType = 6 and Sum < 0, Sum, 0)) as LtActiveToOverdue
        , sum(iif(st.SumType = 'OverdueLt' and psc.ChangeType = 6 and Sum < 0, -Sum, 0)) as LtOverdueToRest
        , sum(iif(st.SumType = 'ActiveLt' and psc.ChangeType = 4, psc.Sum, 0)) as LtPaidActive
        , sum(iif(st.SumType = 'ActiveLt' and po.OperationTemplateId in (7,17,25,26) and psc.ChangeType = 4, psc.Sum, 0)) as LtPaidActiveAoS
        , sum(iif(st.SumType = 'OverdueLt' and psc.ChangeType = 4, psc.Sum, 0)) as LtPaidOverdue
    from acc.ProductSumChange psc
    inner join prd.vw_product p on p.ProductId = psc.ProductId
    left join acc.Document d on d.id = psc.DocumentId
    left join acc.ProductOperation po on po.id = d.ProductOperationId
    left join acc.Account ad on ad.id = d.AccountDtId
    outer apply
    (
        select case
                when psc.SumType in (1001, 1003) and psc.ProductType = 1 and psc.State = 2
                then 'ActiveST'
                when psc.SumType in (1002, 1004) and psc.ProductType = 1 and psc.State = 2
                then 'OverdueST'
                when psc.SumType in (1001, 1003) and psc.ProductType = 2 and psc.State = 2
                then 'ActiveLT'
                when psc.SumType in (1002, 1004) and psc.ProductType = 2 and psc.State = 2
                then 'OverdueLT'
            end as SumType
    ) st
    where psc.ProductType in (1, 2)
        and psc.SumType / 1000 = 1
        and (p.DatePaid is null or p.DatePaid >= '20180101')
    group by cast(psc.BusinessDate as date)
)

select a.date
    , lag(st) over (order by date) as st0
    , lag(stZero) over (order by date) as stZero0
    , lag(lt) over (order by date) as lt0
    , lag(stOp) over (order by date) as stOp0
    , lag(ltOp) over (order by date) as ltOp0

    , a.st
    , a.stZero
    , a.StIssuedLoan
    , a.StActiveToOverdue
    , a.StOverdueToRest
    , isnull(a.StPaidActive, 0) - isnull(a.StPaidActiveAos, 0) as StPaidActive 
    , a.StPaidActiveAos
    , a.stOp 
    , a.StActiveToOverdue * -1 as StOverdueGain
    , a.StOverdueToRest * -1 as StOverdueDrop
    , StPaidOverdue

    , a.Lt
    , a.LtIssuedloan
    , a.LtActiveToOverdue
    , a.LtOverdueToRest
    , isnull(a.LtPaidActive, 0) - isnull(a.LtPaidActiveAos, 0) as LtPaidActive
    , a.LtPaidActiveAos
    , a.ltOp
    , a.LtActiveToOverdue * -1 as LtOverduGain
    , a.LtOverdueToRest * -1 as LtOverdueDrop
    , a.LtPaidOverdue as LtOverduereduce
into #main
from a
where date >= @DateFrom
option (recompile)
;

drop table if exists #OverdueList
;

select 
    sl.ProductId
    , i.InsuranceCost
    , sl.StartedOn as OverdueStart
    , NextSt.OverdueEnd
into #OverdueList
from prd.vw_statusLog sl
inner join prd.vw_product p on p.Productid = sl.ProductId
inner join prd.vw_Insurance i on i.LinkedLoanId = sl.ProductId
    and i.Status != 1
outer apply
(
    select top 1 sl2.StartedOn as OverdueEnd
    from prd.vw_statusLog sl2
    where sl2.ProductId = sl.ProductId
        and sl2.StartedOn > sl.StartedOn
    order by sl2.StartedOn
) NextSt
where sl.Status = 4
;

drop table if exists #debt
;

select
    vars.Date
    , psc.ProductId
    , sum(sum(psc.Sum))over (partition by psc.ProductId 
                                order by vars.Date rows unbounded preceding) as AmountDebt
into #debt
from acc.ProductSumChange psc
outer apply
(
    select cast(psc.BusinessDate as date) as Date
) vars
where psc.SumType in (1001, 1002, 1003, 1004)
    and psc.State = 2
    and psc.ProductType in (1, 2)
    and exists
    (
        select 1 from #OverdueList ol
        where ol.ProductId = psc.ProductId 
    )
group by vars.Date, psc.ProductId
;

create index IX_idebt_Date on #debt(Date)
create index IX_idebt_Product_Date on #debt(ProductId, Date)
;

drop table if exists #BalanceMoments
;

with un as 
(
    -- Баланс на дату старта просрочки
    select
        ol.ProductId
        , ol.OverdueStart as Date
        , d.AmountDebt
        , ol.InsuranceCost
        , 1 as Type
    from #OverdueList ol
    outer apply
    (
        select top 1 d.AmountDebt
        from #debt d
        where d.ProductId = ol.ProductId
            and d.Date <= ol.OverdueStart
        order by d.Date desc
    ) d
    where ol.OverdueStart != cast(ol.OverdueEnd as date)
        or ol.OverdueEnd is null
    
    union 
    
    -- Изменение баланса в период просрочки 
    select
        ol.ProductId
        , d.Date
        , d.AmountDebt
        , ol.InsuranceCost
        , 2 as Type
    from #OverdueList ol
    outer apply
    (
        select isnull(ol.OverdueEnd, cast(getdate() as date)) as OverdueEnd
    ) vars
    cross apply
    (
        select d.Date, d.AmountDebt
        from #debt d
        where d.ProductId = ol.ProductId
            and d.Date > ol.OverdueStart
            and d.Date < vars.OverdueEnd
    ) d
    
    union
    
    -- Баланс на момент выхода из просрочки
    select
        ol.ProductId
        , ol.OverdueEnd
        , 0 as AmountDebt
        , ol.InsuranceCost
        , 3 as Type
    from #OverdueList ol
    where ol.OverdueStart != cast(ol.OverdueEnd as date)
    
    union 
    
    -- Баланс у просроченных на текущий момент
    select
        ol.ProductId
        , cast(getdate() as date) as Date
        , d.AmountDebt
        , ol.InsuranceCost
        , 4 as Type
    from #OverdueList ol
    cross apply
    (
        select top 1 d.AmountDebt
        from #debt d
        where d.ProductId = ol.ProductId
            and d.Date <= cast(getdate() as date)
        order by d.Date desc
    ) d
    where ol.OverdueEnd is null
        and ol.OverdueStart < cast(getdate() as date)
)

select *
into #BalanceMoments
from un
;

select *
from #main m
outer apply
(
    select sum(oi.OverdueInsuranceDebt) as OverdueInsuranceDebt
    from #BalanceMoments bm
    outer apply
    (
        select min(v) as OverdueInsuranceDebt 
        from (values (InsuranceCost), (AmountDebt)) val(v)
    ) oi
    where cast(bm.Date as date) <= m.Date
        and not exists
        (
            select 1 from #BalanceMoments bm2
            where bm2.ProductId = bm.ProductId
                and cast(bm2.Date as date) <= m.Date
                and bm2.Date > bm.Date
        )
) oi