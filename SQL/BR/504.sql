/*
drop table if exists #mm
;

select
    ProductId
    ,mm.date
    ,sum(mm.SumKtNt) as Paid
into #mm
from acc.vw_mm mm
where isDistributePayment = 1
    and left(mm.accNumber, 5) in ('48802', '48803', N'Штраф')
    and mm.Date >= '20180225'
group by ProductId, mm.date
;
*/

with P20162017 as
(
    select
        coalesce(cast(a1.RegionId as int), cast(a2.RegionId as int), 0) as region
        ,datepart(year, op.DateStarted) as Year
        ,count(*) as ProductsTaken
        ,sum(op.Amount) as AmountTaken
        ,count(distinct op.ClientId) as Uniqclients
    from bi.OldProducts op
    outer apply
    (
        select top 1 a1.RegionId
        from client.Address a1 
        where a1.ClientId = op.ClientId
            and a1.AddressType = 1
    ) a1
    outer apply
    (
        select top 1 a2.RegionId
        from client.Address a2
        where a2.ClientId = op.ClientId
            and a2.AddressType = 2
    ) a2
    where DateStarted >= '20160101' 
        and DateStarted < '20180101'
    group by 
        datepart(year, op.DateStarted)
        ,coalesce(cast(a1.RegionId as int), cast(a2.RegionId as int), 0)
)

,P2018 as 
(
    select
        coalesce(cast(a1.RegionId as int), cast(a2.RegionId as int), 0) as region
        ,datepart(year, p.StartedOn) as Year
        ,count(*) as ProductsTaken
        ,sum(p.Amount) as AmountTaken
        ,count(distinct p.ClientId) as Uniqclients
    from prd.vw_Product p
    outer apply
    (
        select top 1 a1.RegionId
        from client.Address a1 
        where a1.ClientId = p.ClientId
            and a1.AddressType = 1
    ) a1
    outer apply
    (
        select top 1 a2.RegionId
        from client.Address a2
        where a2.ClientId = p.ClientId
    ) a2
    where StartedOn >= '20180101'
    group by
        coalesce(cast(a1.RegionId as int), cast(a2.RegionId as int), 0)
        ,datepart(year, p.StartedOn)
) 

,AllYears as 
(
    select * from P20162017
    union
    select * from P2018
)

,debt as 
(
select
    coalesce(cast(a1.RegionId as int), cast(a2.RegionId as int), 0) as region
    ,datepart(year, p.StartedOn) as Year
    ,sum(acc.SaldoNt) * -1 as DebtAmount    
from prd.vw_Product p
left join acc.vw_acc acc on acc.ProductId = p.productid
    and acc.Number like '48801%2'
outer apply
(
    select top 1 a1.RegionId
    from client.Address a1 
    where a1.ClientId = p.ClientId
        and a1.AddressType = 1
) a1
outer apply
(
    select top 1 a2.RegionId
    from client.Address a2
    where a2.ClientId = p.ClientId
        and a2.AddressType = 2
) a2
where p.StartedOn >= '20160101'
    and p.status = 4
group by
    coalesce(cast(a1.RegionId as int), cast(a2.RegionId as int), 0)
    ,datepart(year, p.StartedOn)
)

,PaidSum as 
(
    select
        coalesce(cast(a1.RegionId as int), cast(a2.RegionId as int), 0) as region
        ,datepart(year, opp.DateCreated) as Year
        ,sum(opp.PercentAmount + opp.CommissionAmount + opp.PenaltyAmount + opp.LongPrice + opp.TransactionCosts) as Paid
    from bi.OldProductPayments opp
    inner join bi.OldProducts op on op.ProductId = opp.ProductId
    outer apply
    (
        select top 1 a1.RegionId
        from client.Address a1 
        where a1.ClientId = op.ClientId
            and a1.AddressType = 1
    ) a1
    outer apply
    (
        select top 1 a2.RegionId
        from client.Address a2
        where a2.ClientId =op.ClientId
            and a2.AddressType = 2
    ) a2
    where opp.DateCreated >= '20160101'
        and opp.DateCreated < '20180225'
    group by
        coalesce(cast(a1.RegionId as int), cast(a2.RegionId as int), 0)
        ,datepart(year, opp.DateCreated)
    
    union
    
    select
        coalesce(cast(a1.RegionId as int), cast(a2.RegionId as int), 0) as region
        ,datepart(year, mm.date) as Year
        ,sum(Paid) as Paid
    from #mm mm
    inner join prd.Product p on p.Id = mm.ProductId
    outer apply
    (
        select top 1 a1.RegionId
        from client.Address a1 
        where a1.ClientId = p.ClientId
            and a1.AddressType = 1
    ) a1
    outer apply
    (
        select top 1 a2.RegionId
        from client.Address a2
        where a2.ClientId = p.ClientId
            and a2.AddressType = 2
    ) a2
    group by 
        coalesce(cast(a1.RegionId as int), cast(a2.RegionId as int), 0)
        ,datepart(year, mm.date)
)

,PaidTotal as 
(
    select
        region
        ,year
        ,sum(paid) as paid
    from PaidSum
    group by region, year
)

select
    h.name as region
    ,coalesce(ay.year, d.year, pt.year) as year
    ,ay.ProductsTaken
    ,ay.AmountTaken
    ,ay.Uniqclients
    ,d.DebtAmount
    ,pt.paid
from AllYears ay
full join debt d on ay.year = d.year
    and d.region = ay.region 
full join PaidTotal pt on pt.year = isnull(d.year, ay.year)
    and pt.region = isnull(d.region, ay.region)
left join fias.dict.hierarchy h on h.regioncode = coalesce(d.region, ay.region, pt.region)
    and h.aolevel in (1, 2)
