drop table if exists #Dates
;

select top (datediff(d, '20140331', getdate()) + 1) 
    dateadd(d, row_number() over (order by  so.id), '20140331') - 1 as Dt
into #Dates
from sys.sysobjects so
cross join sys.sysobjects so1
;

with AllProducts as
(
    select
        op.ClientId
        ,op.ProductId
        ,op.Amount
        ,case when TariffId = 4 then 2 else 1 end as ProductType
    from bi.OldProducts op
    where (op.DatePaid < '20180225' or op.DatePaid is null)
        and op.DateStarted < '20180225'
        
    union
    
    select
        p.clientId
        ,p.productid
        ,p.Amount
        ,p.ProductType
    from prd.vw_product p
    where p.status > 2
)

,OldProductsCount as 
(
    select
        cast(p.DateStarted as date) as Dt
        ,count(*) as TotalCredits
        ,count(case when right(p.ContractNumber, 3) = '001' then 1 end) as FirstCredits
        ,count(case when p.TariffId != 4 then 1 end) as STCount
        ,count(case when p.TariffId = 4 then 1 end) as LTCount
        ,sum(case when p.TariffId != 4 then p.Amount else 0 end) as STSum
        ,sum(case when p.TariffId = 4 then p.Amount else 0 end) as LTSum
    from bi.OldProducts p 
    where p.ProductId != 352699
        and (DatePaid < '20180225' or DatePaid is null)
        and p.DateStarted < '20180225'
        and not exists
                (
                    select 1 from prd.vw_product vp
                    where vp.productid = p.ProductId
                        and vp.status < 3
                ) 
        and p.Status not in (5, 8)
        and p.ClientId > 160 and ClientId not in (160, 224, 194, 190, 1770)
    group by cast(p.DateStarted as date)
)

,OldPayments as 
(
    select
        cast(opp.DateCreated as date) as Dt
        ,sum(Amount) as PaidAmnt
        ,sum(PercentAmount)
        + sum(CommissionAmount)
        + sum(PenaltyAmount)
        + sum(TransactionCosts)
        + sum(LongPrice) as PaidOther
        ,sum(case 
                when ops.Status = 3 and datediff(d, ops.DateStarted, opp.DateCreated) + 1 between 1 and 3
                then opp.Amount + opp.PercentAmount + opp.CommissionAmount + opp.PenaltyAmount + opp.LongPrice + opp.TransactionCosts else 0 end) as PaidOverdue1_3
        ,sum(case 
                when ops.Status = 3 and datediff(d, ops.DateStarted, opp.DateCreated) + 1 between 4 and 7
                then opp.Amount + opp.PercentAmount + opp.CommissionAmount + opp.PenaltyAmount + opp.LongPrice + opp.TransactionCosts else 0 end) as PaidOverdue4_7
        ,sum(case 
                when ops.Status = 3 and datediff(d, ops.DateStarted, opp.DateCreated) + 1 between 8 and 14
                then opp.Amount + opp.PercentAmount + opp.CommissionAmount + opp.PenaltyAmount + opp.LongPrice + opp.TransactionCosts else 0 end) as PaidOverdue8_14
        ,sum(case 
                when ops.Status = 3 and datediff(d, ops.DateStarted, opp.DateCreated) + 1 between 15 and 30
                then opp.Amount + opp.PercentAmount + opp.CommissionAmount + opp.PenaltyAmount + opp.LongPrice + opp.TransactionCosts else 0 end) as PaidOverdue15_30
        ,sum(case 
                when ops.Status = 3 and datediff(d, ops.DateStarted, opp.DateCreated) + 1 >= 31
                then opp.Amount + opp.PercentAmount + opp.CommissionAmount + opp.PenaltyAmount + opp.LongPrice + opp.TransactionCosts else 0 end) as PaidOverdue31Plus            
    from bi.OldProductPayments opp
    outer apply
    (
        select top 1 
            ops.Status
            ,ops.DateStarted
        from bi.OldProductStatus ops
        where ops.ProductId = opp.ProductId
            and ops.DateStarted < opp.DateCreated
        order by ops.DateStarted desc
    ) ops
    where opp.DateCreated < '20180225'
    group by cast(opp.DateCreated as date)
)

,NewProductsCount as 
(
    select
        cast(p.StartedOn as date) as Dt
        ,count(*) as TotalCredits
        ,count(case when ap.ProductId = p.ProductId then 1 end) as FirstCredits
        ,count(case when p.productType = 1 then 1 end) as STCount
        ,count(case when p.productType = 2 then 1 end) as LTCount
        ,sum(case when p.productType = 1 then p.Amount else 0 end) as STSum
        ,sum(case when p.productType = 2 then p.Amount else 0 end) as LTSum
    from prd.vw_product p
    outer apply
    (
        select top 1 ap.ProductId
        from AllProducts ap
        where ap.ClientId = p.ClientId
        order by p.ProductId
    ) ap
    where p.StartedOn >= '20180225'
        and p.status > 2
    group by cast(p.StartedOn as date)
)

,NewPayments as 
(
    select
        Date as Dt
        ,sum(case when left(mm.accNumber, 5) = '48801' then mm.SumKtNt end) as PaidAmnt
        ,sum(case when left(mm.accNumber, 5) in ('48802', '48803', N'Штраф') then mm.SumKtNt else 0 end) as PaidOther
        ,sum(case 
                when sl.status = 4 and left(mm.accNumber, 5) in ('48801', '48802', '48803', N'Штраф') 
                 and datediff(d, sl.StartedOn, mm.Date) + 1 between 1 and 3 then mm.SumKtNt else 0 end) as PaidOverdue1_3
        ,sum(case 
            when sl.status = 4 and left(mm.accNumber, 5) in ('48801', '48802', '48803', N'Штраф') 
             and datediff(d, sl.StartedOn, mm.Date) + 1 between 4 and 7 then mm.SumKtNt else 0 end) as PaidOverdue4_7
        ,sum(case 
            when sl.status = 4 and left(mm.accNumber, 5) in ('48801', '48802', '48803', N'Штраф') 
             and datediff(d, sl.StartedOn, mm.Date) + 1 between 8 and 14 then mm.SumKtNt else 0 end) as PaidOverdue8_14
        ,sum(case 
            when sl.status = 4 and left(mm.accNumber, 5) in ('48801', '48802', '48803', N'Штраф') 
             and datediff(d, sl.StartedOn, mm.Date) + 1 between 15 and 30 then mm.SumKtNt else 0 end) as PaidOverdue15_30
        ,sum(case 
            when sl.status = 4 and left(mm.accNumber, 5) in ('48801', '48802', '48803', N'Штраф') 
             and datediff(d, sl.StartedOn, mm.Date) + 1 >= 31 then mm.SumKtNt else 0 end) as PaidOverdue31Plus
    from acc.vw_mm mm
    outer apply
    (
        select top 1 sl.Status, sl.StartedOn
        from prd.vw_statusLog sl
        where sl.ProductType = mm.ProductType
            and sl.ProductId = mm.ProductId
            and sl.StartedOn < dateadd(s, 59 + 59 * 60 + 3600 * 23, mm.Date)
        order by sl.StartedOn desc
    ) sl
    where mm.isDistributePayment = 1
        and mm.Date >= '20180225'
    group by Date
)

,ProductsCount as 
(
    select *
    from NewProductsCount
    
    union
    
    select *
    from OldProductsCount
)

,Payments as 
(
    select *
    from NewPayments
    
    union
    
    select *
    from OldPayments
)

select
    d.Dt
    ,isnull(pc.TotalCredits, 0) as TotalCredits
    ,isnull(pc.FirstCredits, 0) as FirstCredits
    ,isnull(pc.STCount, 0) as STCount
    ,isnull(pc.LTCount, 0) as LTCount
    ,isnull(pc.STSum, 0) as STSum
    ,isnull(pc.LTSum, 0) as LTSum
    ,isnull(p.PaidAmnt, 0) as PaidAmnt
    ,isnull(p.PaidOther, 0) as PaidOther
    ,isnull(p.PaidOverdue1_3, 0) as PaidOverdue1_3
    ,isnull(p.PaidOverdue4_7, 0) as PaidOverdue4_7
    ,isnull(p.PaidOverdue8_14, 0) as PaidOverdue8_14
    ,isnull(p.PaidOverdue15_30, 0) as PaidOverdue15_30
    ,isnull(p.PaidOverdue31Plus, 0) as PaidOverdue31Plus
from #Dates d
left join ProductsCount pc on pc.Dt = d.Dt
left join Payments p on p.Dt = d.Dt