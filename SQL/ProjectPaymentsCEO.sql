set language russian
;

drop table if exists #lime
;

drop table if exists #mango
;

drop table if exists #konga
;

drop table if exists #KongaCards
;

drop table if exists #MangoCards
;

select
    cast(format(cb.DateOperation, 'yyyyMM01') as date) as Mnth
    ,p.ProductType
    ,sum(cb.TotalAmount) as TotalAmount
    ,sum(cb.TotalPercent) as TotalPercent
    ,sum(cb.Fine) as Fine
    ,sum(cb.Commission) as Commission
    ,sum(cb.Prolong) as Prolong
into #lime
from bi.CreditBalance cb
inner join prd.vw_product p on p.Productid = cb.ProductId
where cb.DateOperation >= '20180301'
    and cb.InfoType = 'payment'
group by cast(format(cb.DateOperation, 'yyyyMM01') as date), p.ProductType
;

select
    cast(format(p.DateLastUpdated, 'yyyyMM01') as date) as Mnth
    ,sum(p.Amount) as CardReg
into #KongaCards
from "KONGA-DB".LimeZaim_Website.dbo.payments p
where p.Status = 3
    and p.Type = 2
    and p.DateLastUpdated >= '20180301'
group by cast(format(p.DateLastUpdated, 'yyyyMM01') as date)
;

select
    cast(format(p.DateLastUpdated, 'yyyyMM01') as date) as Mnth
    ,sum(p.Amount) as CardReg
into #MangoCards
from "MANGO-DB".LimeZaim_Website.dbo.payments p
where p.Status = 3
    and p.Type = 2
    and p.DateLastUpdated >= '20180301'
group by cast(format(p.DateLastUpdated, 'yyyyMM01') as date)
;

select
    cast(format(cp.DateCreated, 'yyyyMM01') as date) as Mnth
    ,case when c.TariffId = 4 then 2 else 1 end as ProductType
    ,sum(cp.Amount) as TotalAmount
    ,sum(cp.PercentAmount) as TotalPercent
    ,sum(cp.PenaltyAmount) as Fine
    ,sum(cp.CommissionAmount + cp.TransactionCosts) as Commission
    ,sum(cp.LongPrice) as Prolong
into #konga
from "KONGA-DB".LimeZaim_Website.dbo.CreditPayments cp
inner join "KONGA-DB".LimeZaim_Website.dbo.Payments p on p.id = cp.PaymentId
    and p.Way != 6
inner join "KONGA-DB".LimeZaim_Website.dbo.Credits c on c.id = cp.CreditId
where cp.DateCreated >= '20180301'
group by cast(format(cp.DateCreated, 'yyyyMM01') as date)
    ,case when c.TariffId = 4 then 2 else 1 end
;

select
    cast(format(cp.DateCreated, 'yyyyMM01') as date) as Mnth
    ,case when c.TariffId = 4 then 2 else 1 end as ProductType
    ,sum(cp.Amount) as TotalAmount
    ,sum(cp.PercentAmount) as TotalPercent
    ,sum(cp.PenaltyAmount) as Fine
    ,sum(cp.CommissionAmount + cp.TransactionCosts) as Commission
    ,sum(cp.LongPrice) as Prolong
into #mango
from "MANGO-DB".LimeZaim_Website.dbo.CreditPayments cp
inner join "MANGO-DB".LimeZaim_Website.dbo.Payments p on p.id = cp.PaymentId
    and p.Way != 6
inner join "MANGO-DB".LimeZaim_Website.dbo.Credits c on c.id = cp.CreditId
where cp.DateCreated >= '20180301'
group by cast(format(cp.DateCreated, 'yyyyMM01') as date)
    ,case when c.TariffId = 4 then 2 else 1 end
;

with un as 
(

    select *,'Lime' as Project
    from #lime 
    union all
    select *, 'Konga' 
    from #konga 
    union all
    select *, 'Mango' 
    from #mango
)

,p as 
(
    select
        Mnth
        ,Project
        ,ProductType
        ,N'Тело' as PaymentType
        ,TotalAmount as PaymentSum
    from un
    
    union all
    
    select
        Mnth
        ,Project
        ,ProductType
        ,N'Проценты' as PaymentType
        ,TotalPercent
    from un
    
    union all
    
    select
        Mnth
        ,Project
        ,ProductType
        ,N'Штраф' as PaymentType
        ,Fine
    from un
    
    union all
    
    select
        Mnth
        ,Project
        ,ProductType
        ,N'Комиссия' as PaymentType
        ,Commission
    from un
    
    union all
    
    select
        Mnth
        ,Project
        ,ProductType
        ,N'Продление' as PaymentType
        ,Prolong
    from un
    
    union all
    
    select
        Mnth
        ,'Konga'
        ,1 as ProductType
        ,N'Регистрация карты'
        ,CardReg
    from #KongaCards
    
    union all
    
    select
        Mnth
        ,'Mango'
        ,1 as ProductType
        ,N'Регистрация карты'
        ,CardReg
    from #MangoCards
)

select *
    ,datename(month, Mnth) + format(Mnth, ' yyyy') as MnthName
    ,case PaymentType
        when N'Тело' then 1
        when N'Проценты' then 2
        when N'Штраф' then 3
        when N'Комиссия' then 4
        when N'Продление' then 5
        when N'Регистрация карты' then 6
    end as Sort
        
from p