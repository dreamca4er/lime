/*
declare
    @DateFrom date = '20190101'
    , @DateTo date = '20190620'
;
*/
with c as 
(
    select
        c.id as ClientId
        , lower(left(g.Name, 1)) as Gender
        , c.BirthDate
        , datediff(year, c.BirthDate, getdate()) 
            - iif(datepart(dy, c.BirthDate) < datepart(dy, getdate()), 0, 1) as Age
        , fa.CityName as ActualCityOfResidence
        , e.MonthlyIncome as Income
        , thf.TariffName as InitialTariff
        , thc.TariffName as CurrentTariff
        , pl.CountPaidLoans
    from clt.Client c
    left join clt.EnumGender g on g.id = c.Gender
    left join clt.Address fa on fa.ClientId = c.id
        and fa.AddressType = 2
    left join clt.Employment e on e.id = c.id
    left join Clt.vw_TariffHistory thc on thc.ClientId = c.Id
        and thc.IsLatest = 1
    outer apply
    (
        select top 1 th.TariffName
        from Clt.vw_TariffHistory th
        where th.ClientId = c.id
        order by th.CreatedOn
    ) thf
    outer apply
    (
        select count(*) as CountPaidLoans
        from prd.vw_Product p
        where p.ClientId = c.Id
            and p.Status = 5
    ) pl
)
            
,ll as 
(
    select
        p.ProductId
        , l.LoyaltyLevel
        , p.LoyaltyDiscountFactor as LoyaltyDiscountPercent
        , 1 as IsCurrentLoyalty
    from prd.vw_product p
    outer apply
    (
        select top 1 ls.Level as LoyaltyLevel
        from prd.OperationLog ol
        outer apply openjson(ol.CommandSnapshot, '$.ReductionFactorIds') oj
        inner join mkt.LoyaltyStates ls on ls.id = oj.value
        where ol.ProductId = p.ProductId
            and ol.OperationId = 1
    ) l
    where p.status > 2
        and l.LoyaltyLevel is not null
    
    union all
    
    select
        prf.ProductId
        , p.Name as LoyaltyLevel
        , rf.Factor
        , 0 as IsCurrentLoyalty
    from mkt.ProductReductionFactor prf
    inner join mkt.ClientReductionFactor crf on crf.id = prf.ClientReductionFactorId
    inner join mkt.ReductionFactor rf on rf.id = crf.ReductionFactorId
    inner join mkt.PromoCodes p on p.id = rf.id
        and p.Code like '~Old loyalty%'
)

select
    c.*
    , p.ProductId as CreditID
    , p.TariffName as TariffOfGettingLoan
    , pl.LoanNumber
    , p.CompanyName as Lender
    , rl.RefinancingCycleNumber
    , p.RefinanceFrom as RefinancedCreditID -- Задал вопрос
    , LoyaltyLevel
    , IsCurrentLoyalty
    , ll.LoyaltyDiscountPercent * 100 as LoyaltyDiscountPercent
    , p.Amount
    , initcom.Commission
    , p.StartedOn as OpenDate
    , p.Period
    , p.PayDay as CloseDateByAgreement
    , p.DatePaid as ActualCloseDate
    , p.StatusName as Status
    , iif(p.Status = 4, datediff(d, ls.LastStatusDate, getdate()) + 1, null) as DaysOfOverdue
    , currbal.Amount as PrincipalAmountDebt
    , currbal.OverdueAmount as OverdueAmountDebt
    , currbal.CommissionAmount as CommissionDebt
    , currbal.OverdueCommissionAmount as OverdueCommissionDebt
    , currbal.Interest as DailyPercentDebt
    , currbal.OverdueInterest as OverduePercentDebt
    , isnull(paid.Amount, 0) as PrincipalAmountPaid
    , isnull(paid.OverdueAmount, 0) as OverdueAmountPaid
    , isnull(paid.CommissionAmount, 0) as CommissionPaid
    , isnull(paid.OverdueCommissionAmount, 0) as OverdueCommissionPaid
    , isnull(paid.Interest, 0) as DailyPercentPaid
    , isnull(paid.OverdueInterest, 0) as OverduePercentPaid
from prd.vw_product p
left join c on c.ClientId = p.ClientId
left join ll on ll.ProductId = p.ProductId
outer apply
(
    select count(*) as LoanNumber
    from prd.vw_Product p2
    where p2.ClientId = p.ClientId
        and p2.Status > 2
        and p2.StartedOn <= p.StartedOn
) pl
outer apply
(
    select nullif(count(*), 0) as RefinancingCycleNumber
    from prd.RefinanceLog rl
    where rl.RootId = p.RefinanceRoot
        and rl.DestinationId <= p.ProductId
) rl
outer apply
(
    select top 1 cb.CommissionAmount as Commission
    from bi.CreditBalance cb
    where cb.InfoType = 'debt'
        and cb.ProductId = p.ProductId
    order by cb.BusinessDate     
) initcom
outer apply
(
    select max(sl.StartedOn) as LastStatusDate
    from prd.vw_statusLog sl
    where sl.ProductId = p.ProductId
) ls
outer apply
(
    select top 1 
        cb.*
    from bi.CreditBalance cb
    where cb.InfoType = 'debt'
        and cb.ProductId = p.ProductId
    order by cb.BusinessDate desc
) currbal
outer apply
(
    select
        sum(cb.Amount) as Amount
        , sum(cb.OverdueAmount) as OverdueAmount
        , sum(cb.CommissionAmount) as CommissionAmount
        , sum(cb.OverdueCommissionAmount) as OverdueCommissionAmount
        , sum(cb.Interest) as Interest
        , sum(cb.OverdueInterest) as OverdueInterest
        , sum(cb.ProlongationOldPl) as ProlongationOldPl
    from bi.CreditBalance cb
    where cb.InfoType = 'payment'
        and cb.ProductId = p.ProductId
) paid
where p.Status > 2
    and cast(p.StartedOn as date) between @DateFrom and @DateTo