--drop table if exists #mp
select
    cast(mp.MintosId as int) as MintosId
    , mp.Amount as MintosAmount
    , mp.ConditionSnapshot
into #mp
from mts.MintosProduct mp

create index IX_mts_MintosProduct on #mp(MintosId)
/
--drop table if exists #pay;

with p as 
(
    select 
        p.id as MintosId
        , p.status
        , pr.Productid
        , pr.DatePaid
        , mp.MintosAmount
        , ExchangeRate as EuroExchangeRate
        , InterestRate
        , InterestAmount
    from dbo.br7999Parsed p
    left join prd.vw_product pr on pr.Productid = p.lender_id
    left join #mp mp on mp.MintosId = p.id
    outer apply openjson(mp.ConditionSnapshot) with
    (
        ExchangeRate numeric(18, 6) '$.ExchangeRate'
        , ExchangeRateDate datetime2 '$.ExchangeRateDate'
        , InterestAmount numeric(18, 2) '$.InterestAmount'
        , InterestRate numeric(18, 2) '$.InterestRate'
    ) cs
)


/*
select
    cb.DateOperation
    , cb.ProductId
    , p.MintosAmount
    , sum(cb.TotalDebt) over (partition by cb.ProductId order by cb.DateOperation) as RunningPaid
    , sum(cb.TotalDebt) over (partition by cb.ProductId) as PaidTotal
into #pay
from bi.CreditBalance cb
inner join p on p.Productid = cb.Productid
where cb.infotype = 'payment'

create index IX_pay_ProductId_DateOperation on #pay(ProductId, DateOperation)
/
*/

,j(Products) as
--,j as 
(
    select
        p.MintosId
        , p.ProductId
        , isnull(PaidAll.DateOperation, PaidPart.DateOperation) as PaymentDate
        , isnull(PaidAll.PaymentSum, PaidPart.PaymentSum) as PaymentSum
        , p.EuroExchangeRate as ExchangeRate
        , p.MintosAmount
        , p.InterestRate
        , p.InterestAmount
    from p
    outer apply
    (
        select top 1
            pay.DateOperation
            , pay.MintosAmount as PaymentSum
        from #pay pay
        where pay.ProductId = p.ProductId
            and pay.PaidTotal >= pay.MintosAmount
            and pay.RunningPaid >= pay.MintosAmount
        order by pay.DateOperation 
    ) PaidAll
    outer apply
    (
        select top 1
            pay.DateOperation
            , pay.RunningPaid as PaymentSum
        from #pay pay
        where pay.ProductId = p.ProductId
            and pay.PaidTotal < pay.MintosAmount
        order by pay.DateOperation desc
    ) PaidPart
    where 1=1
        and isnull(PaidAll.PaymentSum, PaidPart.PaymentSum) is null
        and p.Status = 'active'
    for json auto, include_null_values
)

select *
from j

