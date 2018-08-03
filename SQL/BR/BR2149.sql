/*
declare
    @dateFrom date = '20170501'
    ,@dateTo date = cast(getdate() as date)
    ,@ProductType int = 1
    ,@AddCommission int = 0
;

drop table if exists #prd
;

drop table if exists #paid
;
*/
set language russian
;

select *
into #prd
from
(
    select
        op.ClientId
        ,op.ProductId
        ,op.Amount
        ,case when op.TariffId = 4 then 2 else 1 end as ProductType
        ,dateadd(month, datediff(month, 0, op.DateStarted), 0) as StartedOn
    from bi.OldProducts op
    where (op.DatePaid < '20180225' or op.DatePaid is null)
        and op.DateStarted < '20180225'
        and cast(op.DateStarted as date) between @dateFrom and @dateTo
       
    union
   
    select
        p.clientId
        ,p.productid
        ,p.Amount
        ,p.ProductType
        ,dateadd(month, datediff(month, 0, p.StartedOn), 0)
    from prd.vw_product p
    where p.status > 2
        and cast(p.StartedOn as date) between @dateFrom and @dateTo
        and p.StartedOn >= '20180225'
) AllProducts
where ProductType in (@ProductType)
;

select *
into #paid
from
(
    select
        pn.ProductId
        ,pn.ProductType
        ,pn.StartedOn as ProductStartedOn
        ,dateadd(month, datediff(month, 0, opp.DateCreated), 0) as PaymentMonth
        ,opp.Amount as AmountPaid
        ,opp.Amount + opp.PercentAmount + opp.PenaltyAmount + opp.TransactionCosts * @AddCommission as TotalPaid
    from bi.OldProductPayments opp
    inner join #prd pn on pn.ProductId = opp.ProductId
    where cast(opp.DateCreated as date) between @dateFrom and @dateTo
        and opp.DateCreated < '20180225'
    
    union all
    
    select
        pn.ProductId
        ,pn.ProductType
        ,pn.StartedOn as ProductStartedOn
        ,dateadd(month, datediff(month, 0, cast(cb.DateOperation as date)), 0) as PaymentMonth
        ,cb.TotalAmount as AmountPaid
        ,cb.TotalAmount + cb.TotalPercent + cb.Fine + cb.Commission * @AddCommission as TotalPaid
    from bi.CreditBalance cb
    inner join #prd pn on pn.ProductId = cb.ProductId
    where cast(cb.DateOperation as date) between @dateFrom and @dateTo
        and cb.DateOperation >= '20180225'
        and cb.InfoType = 'payment'
) paid
;

with prd as 
(
    select
        StartedOn as Mnth
        ,ProductType
        ,count(*) as ProductCount
        ,sum(Amount) as AmountTaken
    from #prd 
    group by StartedOn, ProductType
)

,paid as 
(
    select
        ProductStartedOn
        ,PaymentMonth
        ,ProductType
        ,sum(AmountPaid) as AmountPaid
        ,sum(TotalPaid) as TotalPaid
    from #paid
    group by 
        ProductStartedOn
        ,PaymentMonth
        ,ProductType
)

select
    prd.ProductType
    ,prd.Mnth as ProductStartedOn
    ,datename(month, prd.Mnth) + format(prd.Mnth, ' yyyy') as ProductStartedOnMonthName
    ,paid.PaymentMonth
    ,datename(month, paid.PaymentMonth) + format(paid.PaymentMonth, ' yyyy') as PaymentMonthName
    ,prd.ProductCount
    ,prd.AmountTaken
    ,paid.AmountPaid as SumPaid
    ,'AmountPaid' as PaidSumType
from prd
left join paid on prd.Mnth = paid.ProductStartedOn
    and prd.ProductType = paid.ProductType

union

select
    prd.ProductType
    ,prd.Mnth as ProductStartedOn
    ,datename(month, prd.Mnth) + format(prd.Mnth, ' yyyy') as ProductStartedOnMonthName
    ,paid.PaymentMonth
    ,datename(month, paid.PaymentMonth) + format(paid.PaymentMonth, ' yyyy') as PaymentMonthName
    ,prd.ProductCount
    ,prd.AmountTaken
    ,paid.TotalPaid as SumPaid
    ,'TotalPaid' as PaidSumType
from prd
left join paid on prd.Mnth = paid.ProductStartedOn
    and prd.ProductType = paid.ProductType