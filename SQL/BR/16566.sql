declare 
    @EuroRate numeric(18, 4) = 69.2013
    , @ReportType int = 2
    , @ReportPart int = 1
    , @PublishSumEuro int = 400000
    , @PublishDaysBack int = 40
    , @dateFrom date = '20191201'
    , @dateTo date = '20191230'
;
exec bi.sp_BondsterList
@EuroRate = @EuroRate
, @ReportType = @ReportType
, @ReportPart = @ReportPart
, @PublishSumEuro = @PublishSumEuro
, @PublishDaysBack = @PublishDaysBack
, @dateFrom = @dateFrom
, @dateTo = @dateTo
;

create or alter procedure bi.sp_BondsterList
(
    @EuroRate numeric(18, 4)
    , @ReportType int
    , @ReportPart int
    , @PublishSumEuro int
    , @PublishDaysBack int
    , @dateFrom date
    , @dateTo date
)
as 
/**************************************
@ReportType - Тип выгрузки:
    1 - Не опубликованные займы
    2 - Опубликованные займы

@ReportPart - Часть отчета:
    1 - Список займов, опубликованных или нет
    2 - График платежей для не опубликованных займов

**************************************/
begin
    drop table if exists #pre
    drop table if exists #p
    ;
    
    with p as 
    (
        select
            p.Productid as "Loan ID"
            , p.ContractNumber as "Contract number"
            , 'Consumer Loan' as "Loan Type"
            , 'Eur' as Currency
            , 'Russia' as Country
            , round(p.Amount / er.EuroRate, 2) as "Loan Amount"
            , round(cb.CurrentAmount  / er.EuroRate, 2) as "Current Debtor Principal"
            , p.Psk as "Loan Agreement Interest Rate"
            , 14 as "Frequency of Repayments"
            , p.StartedOn as "Loan Origination date"
            , p.Period as "Loan Maturity"
            , p.ClientId as "Debtor ID"
            , 'Individual' as "Debtor Type"
            , c.BirthDate as "Debtor D.O.B"
            , iif(c.SexKind = 1, 'Male', 'Female') as "Gender"
            , addr.City as "Debtor Residence Location"
            , p.ContractPayDay as "Repayment date"
            , round(lts.PercentWithDiscount / er.EuroRate, 2) as Interest
            , round(isnull(cb.CommissionAmount / er.EuroRate, 0), 2) as Commission 
            , p.StatusEngName as "Loan status"
            , isnull(round(paid.AmountPaid / er.EuroRate, 2), 0) as AmountPaid
            , isnull(round(paid.InterestPaid / er.EuroRate, 2), 0) as InterestPaid
            , isnull(round(paid.CommissionPaid / er.EuroRate, 2), 0) as CommissionPaid
            , sum(p.Amount / er.EuroRate) over (order by p.CreatedOn desc, p.ProductId desc) as RunningAmount
            , isnull(bp.PublishedOn, getdate()) as PublishedOn
            , er.EuroRate
            , p.DatePaid
            
            , bp.ProductId as BondsterProductId
            , p.Status
            , p.StartedOn
            , paid.TotalPaid
        from prd.vw_product p
        inner join client.Client c on c.Id = p.ClientId
        left join bi.BondsterProducts bp on bp.ProductId = p.Productid
        outer apply
        (
            select top 1 a.City
            from client.vw_address a
            where a.ClientId = p.ClientId
            order by a.AddressType desc 
        ) addr
        outer apply
        (          
            select
                sum(iif(psj.SumType = 1001 and psj.ChangeType in (1, 9), psj.RawSum, 0)) as TotalAmount
                , sum(iif(psj.SumType / 1000 = 1, psj.Sum, 0)) as CurrentAmount
                , sum(iif(psj.SumType = 4011 and psj.ChangeType = 3, psj.RawSum, 0)) as CommissionAmount
            from acc.ProductSumJournal psj
            where 1=1
                and psj.ProductId = p.Productid
                and psj.ProductType = p.ProductType
                and psj.SumType in (1001, 4011)
        ) cb
        outer apply
        (
            select
                sum(cb.TotalDebt) as TotalPaid
                , sum(cb.TotalAmount) as AmountPaid
                , sum(cb.TotalPercent) as InterestPaid
                , sum(cb.Commission) as CommissionPaid
            from bi.CreditBalance cb
            where cb.ProductId = p.Productid
                and cb.InfoType = 'payment'
        ) paid
        outer apply
        (
            select sum(PercentWithDiscount) as PercentWithDiscount
            from prd.LongTermSchedule lts
            outer apply openjson(ScheduleSnapshot) 
                with (PercentWithDiscount numeric(18, 2) '$.PercentWithDiscount') s
            where lts.ProductId = p.Productid
                and SchType = 1
        ) lts
        outer apply
        (
            select isnull(bp.EuroRate, @EuroRate) as EuroRate
        ) er
        where 1=1
            and p.ProductType = 2
            and isnull(p.ScheduleCalculationType, 1) = 1
            and (p.Status = 3 or bp.ProductId is not null)
    )
    
    select *
    into #pre
    from p
    ;
    
    with NotPublished as 
    (
        select *
        from #pre p
        where @ReportType = 1
            and p.BondsterProductId is null -- bp.ProductId is null
            and p.Status = 3
            and p.StartedOn >= dateadd(d, -@PublishDaysBack, getdate())
            and p.RunningAmount <= @PublishSumEuro
            and p.TotalPaid is null -- paid.TotalPaid is null
            and not exists
            (
                select 1 from pmt.vw_Payment pay
                where pay.ContractNumber = p."Contract number" -- p.ContractNumber
                    and pay.PaymentDirection = 2
                    and pay.PaymentStatus = 5
                    and pay.ProcessedOn >= cast(getdate() as date)
            )
    )
    
    ,Published as 
    (
        select *
        from #pre p
        where @ReportType = 2
            and p.BondsterProductId is not null -- bp.ProductId is not null
            and cast(p.PublishedOn as date) between @dateFrom and @dateTo -- bp.PublishedOn
    )
    
    ,p as 
    (
        select * from NotPublished
        
        union all
        
        select * from Published
    )
    
    select
        "Loan ID"
        , "Contract number"
        , "Loan Type"
        , "Currency"
        , "Country"
        , "Loan Amount"
        , "Current Debtor Principal"
        , "Loan Agreement Interest Rate"
        , "Frequency of Repayments"
        , "Loan Origination date"
        , "Loan Maturity"
        , "Debtor ID"
        , "Debtor Type"
        , "Debtor D.O.B"
        , "Gender"
        , "Debtor Residence Location"
        , "Repayment date"
        , cast(p.DatePaid as date) as "Actual repayment date"
        , "Loan Amount" as "Principal"
        , "Interest"
        , "Commission"
        , AmountPaid as "Principal Amount Paid"
        , InterestPaid as "Interest Paid"
        , CommissionPaid as "Commission Paid"
        , "Loan status"
        , "PublishedOn"
        , "EuroRate"
    into #p
    from p
    where p.RunningAmount <= @PublishSumEuro
        and @ReportType = 1
        or @ReportType = 2
    ;
    
    if @ReportPart = 1
        select * from #p
    if @ReportPart = 2 and @ReportType = 1
        with s as 
        (
            select 
                p."Loan ID"
                , row_number() over (partition by p."Loan ID" order by sched."INSTALLMENT DATE") as "NO. OF INSTALMENT"
                , row_number() over (partition by p."Loan ID" order by sched."INSTALLMENT DATE" desc) as rnDesc
                , sched."INSTALLMENT DATE"
                , round(sched.Amount / p.EuroRate, 2) as "PRINCIPAL"
                , round(sched.PercentWithDiscount / p.EuroRate, 2) as "INTEREST"
                , Commission
                , 0 as "PAID PRINCIPAL"
                , 0 as "PAID INTEREST"
                , 0 as "PAID COMMISSION"
            from #p p
            inner join prd.LongTermSchedule lts on lts.ProductId = p."Loan ID"
            outer apply openjson(lts.ScheduleSnapshot) with
            (
                "INSTALLMENT DATE" date '$.Date'
                , Amount numeric(18 ,2) '$.Amount'
                , PercentWithDiscount numeric(18 ,2) '$.PercentWithDiscount'
            ) sched
            where lts.SchType = 1
        )
        
        select
            "Loan ID"
            , "NO. OF INSTALMENT"
            , "INSTALLMENT DATE"
            , "PRINCIPAL"
            , "INTEREST"
            , iif("rnDesc" = 1, Commission, 0) as "COMMISSION"
            , "PAID PRINCIPAL"
            , "PAID INTEREST"
            , "PAID COMMISSION"
        from s
        order by 1, 2
end