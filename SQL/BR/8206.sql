--drop table if exists #mp
select
    cast(mp.MintosId as int) as MintosId
    , mp.Amount as MintosAmount
    , mp.ConditionSnapshot
into #mp
from mts.MintosProduct mp
where mp.CreatedOn < '20190305'

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
    from dbo.br7999Parsed p
    left join prd.vw_product pr on pr.Productid = p.lender_id
    left join #mp mp on mp.MintosId = p.id
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

--,j(Products) as
,j as 
(
    select
        p.MintosId
        , p.ProductId
        , iif(PaidAll.PaymentSum > 0, 4, 3) as MintosState
        , isnull(PaidAll.PaymentSum, PaidPart.PaymentSum) as PaymentSum
        , p.MintosAmount
        
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
)

select *
into #mintos
from j
/

select *
from #mintos

create index IX_mintos_MintosId on #mintos(MintosId)
/

select *
from #mintos

select top 100 mp.Amount, m.MintosAmount, mp.Status, m.MintosState
-- update mp set Status = m.MintosState
from mts.MintosProduct mp
inner join #mintos m on m.MintosId = mp.MintosId
where 1=1
    and mp.Status != m.MintosState

insert mts.MintosProductStatusLog
(
   CreatedOn,CreatedBy,StartedOn,Status,ProductId
)
select
    getdate() as CreatedOn
    , 0x44 as CreatedBy
    , getdate() as StartedOn
    , mp.Status
    , mp.Id as ProductId
from mts.MintosProduct mp
outer apply
(
    select top 1 ps.Status
    from mts.MintosProductStatusLog ps
    where ps.ProductId = mp.Id
    order by ps.StartedOn desc
) ps
where 1=1
    and mp.Status in (3, 4)
    and Timestamp >= 0x000000008fe30788 
    and ps.Status != mp.Status
    /
select *
from bi.RowVersionSnapshot
where Date >= '20190422'
/

select *  -- update cc set CreditCardStatus = 1
from client.CreditCard cc
where id = 1285895

select *
from client.EnumCreditCardStatus