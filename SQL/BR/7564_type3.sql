/*
804003 Погашен со скидкой (частичной)
803974 Погашен 100% скидка
803966 Погашен без скидки
728228 Погашен, несколько платежей, в разные дни, гасил штраф
736838 Погашен, несколько платежей, в один день, с разных каналов

729357 Не погашен, несколько платежей, в один день
687948 Не погашен, несколько платежей, в один день, с разных каналов + есть платежи в другой день

446209 Несколько % ставок

453339
415747 старый скидочный
442649 Перерасчет процентов
450145

'1900120664' 442099
'1900323374'  566394
'1900393034' 611098

*/


set ansi_warnings off
;

declare
    @ProductId int  = 611098
    , @ReportDate date 
;

declare
    @ProductType int = (select ProductType from prd.Product where Id = @ProductId)
;

set @ReportDate = '20190501'
;

set @ReportDate = isnull
    (
        (    
            select top 1 sl.StartedOn
            from prd.vw_statusLog sl
            where sl.ProductId = @ProductId
                and sl.Status in (5, 6)
            order by sl.StartedOn desc 
        )
        , @ReportDate
    )
;

drop table if exists #dates
;

select d.dt1 as Date, row_number() over (order by d.dt1 desc) as DateNum
into #dates
from prd.Product p
outer apply bi.tf_gendate(cast(p.StartedOn as date), @ReportDate) d
where p.id = @ProductId
    and d.dt1 <= cast(getdate() as date)
;

drop table if exists #mm
;

select
    ProductId
    , cast(DateOperation as date) as DateOperation
    , accNumber
    , Description
    , SumKtNt
    , opSum
    , isDistributePayment
    , OperationTemplateId
into #mm
from acc.vw_mm mm
where mm.ProductId = @ProductId
    and mm.ProductType = @ProductType
;

with ppd as 
(
    select
        perc.StartedOn as PercentPerDayStartedOn
        , iif(p.PrivilegeType = 2
            , perc.PercentPerDay
            , perc.PercentPerDay * perc.PrivilegeFactor) / 100 as PercentPerDay
        , perc.PercentPerDay / 100 as PercentPerDayWithoutDiscount
        , perc.PenaltyPercent / 100 as PenaltyPercent
    from prd.vw_product p
    outer apply openjson(ConditionSnapshot) with
    (
        StartedOn datetime '$.StartedOn'
        , PercentPerDay numeric(5, 2) '$.PercentPerDay'
        , PrivilegeFactor numeric(5, 2) '$.PrivilegeFactor'
        , PenaltyPercent numeric(5, 2) '$.PenaltyPercent' 
    ) perc
    where p.ProductId = @ProductId
)

,payments as 
(
    select
        pay.id as PaymentId
        , pay.Amount
        , cast(pay.ProcessedOn as date) as PaymentDate
        , isnull(N'Карта ' + ccpi.NumberMasked, pw.Description) as PaymentSource
        , cast(pr.StartedOn as date) as ProductStartedOn
        , pay.PaymentDirection
    from pmt.Payment pay
    inner join prd.Product pr on pr.ContractNumber = pay.ContractNumber
    inner join pmt.EnumPaymentWay pw on pw.id = pay.PaymentWay
    left join pmt.CreditCardPaymentInfo ccpi on ccpi.PaymentId = pay.id
    where pr.id = @ProductId
        and pay.PaymentStatus = 5
)

,dates as 
(
    select 
        d.Date
        , iif(os.HadOverdue = 1, ppd.PercentPerDayWithoutDiscount, ppd.PercentPerDay) as PercentPerDay
        , ppd.PenaltyPercent
        , isnull(debt.DebtAmount, 0) as DebtAmount
        , isnull(debt.DebtPercent, 0) as DebtPercent
        , isnull(debt.DebtFine, 0) as DebtFine
        , isnull(debt.DebtCommission, 0) as DebtCommission
        , isnull(debt.TotalDebt, 0) as TotalDebt
        , isnull(paid.PaidAmount, 0) as PaidAmount
        , isnull(paid.PaidPercent, 0) as PaidPercent
        , isnull(paid.PaidFine, 0) as PaidFine
        , isnull(paid.PaidCommission, 0) as PaidCommission
        , isnull(paid.PaidProlong, 0) as PaidProlong
        , isnull(paid.TotalPaid, 0) as TotalPaid
        , isnull(ops.ChargedPercent, 0) as ChargedPercent
        , isnull(ops.ChargedFine, 0) as ChargedFine
        , isnull(ops.DiscountAmount, 0) as DiscountAmount
        , isnull(ops.PercentRecalcAmount, 0) as PercentRecalcAmount
        , sl.Status
        , iif(sl.Status in (3, 4, 7) and d.DateNum = 1, 1, 0) as CurrentDate
    from #dates d
    outer apply
    (
        select top 1
            ppd.PercentPerDay
            , ppd.PercentPerDayWithoutDiscount
            , ppd.PenaltyPercent
        from ppd
        where ppd.PercentPerDayStartedOn < d.Date
        order by ppd.PercentPerDayStartedOn desc
    ) ppd
    outer apply
    (
        select top 1 
            cb.TotalAmount * -1 as DebtAmount
            , cb.TotalPercent * -1 as DebtPercent
            , cb.Fine * - 1 as DebtFine
            , cb.Commission * -1 as DebtCommission
            , cb.TotalDebt * -1 as TotalDebt
        from bi.CreditBalance cb
        where cb.InfoType = 'debt'
            and cb.ProductId = @ProductId
            and cb.DateOperation <= d.Date
        order by cb.DateOperation desc
    ) debt
    outer apply
    (
        select 
            sum(cb.TotalAmount) as PaidAmount
            , sum(cb.TotalPercent) as PaidPercent
            , sum(cb.Fine) as PaidFine
            , sum(cb.Commission) as PaidCommission
            , sum(cb.Prolong) as PaidProlong
            , sum(cb.TotalDebt) as TotalPaid
        from bi.CreditBalance cb
        where cb.InfoType = 'payment'
            and cb.ProductId = @ProductId
            and cast(cb.DateOperation as date) = d.Date
    ) paid
    outer apply
    (
        select
            sum(case when mm.accNumber like '48802%' and mm.OperationTemplateId = 5 then mm.opSum end) * -1 as ChargedPercent
            , sum(case when mm.accNumber like N'Штраф%' and mm.OperationTemplateId = 5 then mm.opSum end) * -1 as ChargedFine
            , sum(case when mm.IsDistributePayment = 2 then mm.SumKtNt end) as DiscountAmount
            , sum(case when mm.IsDistributePayment = 5 then mm.SumKtNt * -1 end) as PercentRecalcAmount
        from #mm mm
        where mm.DateOperation = d.Date
    ) ops
    outer apply
    (
        select top 1 1 as HadOverdue
        from prd.vw_statusLog sl
        where sl.productid = @ProductId
            and sl.Status = 4
            and sl.StartedOn <= d.Date
        order by sl.StartedOn desc
    ) os
    outer apply
    (
        select top 1 sl.Status
        from prd.vw_statusLog sl
        where sl.productid = @ProductId
            and cast(sl.StartedOn as date) <= d.Date
        order by sl.StartedOn desc
    ) sl
)

,AggPayments as 
(
    select
        p.PaymentDate as Date
        , sum(p.Amount) as PaymentAmount
        , isnull(lag(p.PaymentDate) over (order by p.PaymentDate), p.ProductStartedOn) as PrevDate
    from payments p
    where p.PaymentDirection = 2
    group by p.PaymentDate, p.ProductStartedOn
)

-- Тут собираем даты, которые нужно выводить в отчет
,ReportDates as 
(
    select
        d.Date
        , 0 as PaymentAmount
        , isnull(pay.PrevDate, p.StartedOn) as PrevDate
        , 1 as dt
    from prd.product p, dates d
    outer apply
    (
        select max(Date) as PrevDate
        from AggPayments
    ) pay
    where CurrentDate = 1
        and p.id = @ProductId
    
    union all
    
    select *, 2 as dt from AggPayments
)

,ReportDatesAgg as 
(
    select
        ap.Date
        , d.PercentPerDay
        , d.PenaltyPercent
        , d.DebtAmount
        , sum(iif(d.ChargedPercent > 0, 1, 0)) as PercentDays
        , sum(iif(d.ChargedFine > 0, 1, 0)) as FineDays
        , sum(d.ChargedPercent) as ChargedPercent
        , sum(d.ChargedFine) as ChargedFine
        , sum(iif(d.Date < ap.Date, d.DiscountAmount, 0)) as MidPeriodDiscountAmount
        , sum(iif(d.Date = ap.Date, d.DiscountAmount, 0)) as DiscountAmount
        , sum(iif(d.Date < ap.Date, d.PercentRecalcAmount, 0)) as MidPeriodPercentRecalcAmount
        , sum(iif(d.Date = ap.Date, d.PercentRecalcAmount, 0)) as PercentRecalcAmount
    from ReportDates ap
    inner join dates d on (d.Date > ap.PrevDate or d.Date = ap.Date and ap.Date = ap.PrevDate)
        and d.Date <= ap.Date
        and 
        (
            d.ChargedFine > 0
            or d.ChargedPercent > 0
            or d.TotalPaid > 0
            or d.DiscountAmount > 0
            or d.PercentRecalcAmount > 0
            or ap.dt = 1 -- Для незакрытых кредитов выводим дополнительно текущие балансы
        )
    group by 
        ap.Date
        , d.DebtAmount
        , d.PercentPerDay
        , d.PenaltyPercent
)

,ReportDatesCalculations as 
(
    select
        @ProductId as ProductId
        , *
        , round(DebtAmount * PercentPerDay, 2) * PercentDays as CalculatedChargedPercent
        , round(DebtAmount * PenaltyPercent / 365, 2) * FineDays as CalculatedChargedFine
    from ReportDatesAgg
)

,ReportDatesChargeFormulas as 
(
    select
        rd.Date
        , replace(replace(replace(replace(replace(perc.Formula
                , '"PercentFormula":', '')
                , '"', '')
                , ',', ' + ')
                , '{', '')
                , '}', '') as ChargedPercentFormula
        , replace(replace(replace(replace(replace(replace(fine.Formula
                , '"FineFormula":', '')
                , '"', '')
                , ',', ' + ')
                , '{', '')
                , '}', '')
                , '\/', '/') as ChargedFineFormula
        , sum(rd.CalculatedChargedPercent) as CalculatedChargedPercent
        , sum(rd.CalculatedChargedFine) as CalculatedChargedFine
        , sum(rd.ChargedPercent) as ChargedPercent
        , sum(rd.ChargedFine) as ChargedFine
        , sum(rd.DiscountAmount) as DiscountAmount
        , sum(rd.MidPeriodDiscountAmount) as MidPeriodDiscountAmount
        , sum(rd.PercentRecalcAmount) as PercentRecalcAmount
        , sum(rd.MidPeriodPercentRecalcAmount) as MidPeriodPercentRecalcAmount
    from ReportDatesCalculations rd
    outer apply
    (
        select
            format(rdc.DebtAmount, '0.##')
            + ' * '
            + format(rdc.PercentPerDay, '0.####%')
            + ' * '
            + cast(rdc.PercentDays as nvarchar(5)) as PercentFormula
        from ReportDatesCalculations rdc
        where rd.Date = rdc.Date
            and rdc.PercentDays > 0
        for json auto, without_array_wrapper
    ) perc (Formula)
    outer apply
    (
        select
            format(rdc.DebtAmount, '0.##')
            + ' * '
            + format(rdc.PenaltyPercent, '0.####%')
            + ' / 365 * '
            + cast(nullif(rdc.FineDays, 0) as nvarchar(5)) as FineFormula
        from ReportDatesCalculations rdc
        where rd.Date = rdc.Date
            and rdc.FineDays > 0
        for json auto, without_array_wrapper
    ) fine (Formula)
    group by rd.date, perc.Formula, fine.Formula
)

,Prep as 
(
    select
        rdf.Date
        , isnull(rdf.ChargedPercentFormula, 0) as ChargedPercentFormula
        , isnull(rdf.ChargedFineFormula, 0) as ChargedFineFormula
        , rdf.CalculatedChargedPercent
        , rdf.CalculatedChargedFine
        , rdf.ChargedPercent
        , rdf.ChargedFine
        , rdf.DiscountAmount
        , rdf.MidPeriodDiscountAmount
        , rdf.PercentRecalcAmount
        , rdf.MidPeriodPercentRecalcAmount
        , case
            when rdf.CalculatedChargedPercent != rdf.ChargedPercent
            then 'WrongPercent'
            when rdf.CalculatedChargedFine != rdf.ChargedFine
            then 'WrongFine'
        end as Errors 
        , replace(replace(replace(ps.PaymentSources
                    , '{"PaymentSource":"', '')
                    , '"}', '')
                    , ',', char(10)) as PaymentSources
        , d.DebtAmount
        , d.DebtPercent
        , d.DebtFine
        , d.DebtCommission
        , d.TotalDebt
        , d.PaidAmount
        , d.PaidPercent
        , d.PaidFine
        , d.PaidCommission
        , d.PaidProlong
        , d.TotalPaid
        , isnull(lag(d.DebtPercent) over (order by rdf.Date), 0) as PrevDebtPercent
        , isnull(lag(d.DebtFine) over (order by rdf.Date), 0) as PrevDebtFine
        , isnull(lag(d.DiscountAmount)over (order by rdf.Date), 0) as PrevDiscountAmount
        , isnull(lag(d.PercentRecalcAmount)over (order by rdf.Date), 0) as PrevPercentRecalcAmount
        , isnull(lag(d.PaidPercent)over (order by rdf.Date), 0) as PrevPaidPercent
        , isnull(lag(d.PaidFine)over (order by rdf.Date), 0) as PrevPaidFine
    from ReportDatesChargeFormulas rdf
    left join dates d on d.Date = rdf.Date
    outer apply
    (
        select p.PaymentSource
        from payments p
        where p.PaymentDate = rdf.Date
            and p.PaymentDirection = 2
        for json auto, without_array_wrapper
    ) ps(PaymentSources)
)

select
    replace(replace(replace(replace(replace(replace(replace(
        format(prep.DebtPercent, '#0.##') + isnull(' = ' + fp.PercentFormula, '')
            , '"val":', '')
            , '"op":', '')
            , '{', '')
            , '}', '')
            , ',', '')
            , '"', '')
            , '=  + ', '= ') as PercentFormula
    , replace(replace(replace(replace(replace(replace(replace(replace(
        format(prep.DebtFine, '#0.##') + isnull(' = ' + ff.FineFormula, '')
            , '"val":', '')
            , '"op":', '')
            , '{', '')
            , '}', '')
            , ',', '')
            , '"', '')
            , '=  + ', '= ')
            , '\/', '/') as FineFormula
    , prep.*
from prep
outer apply
(
    select Comp.op, Comp.val
    from
    (
        values
        (null, format(prep.PrevDebtPercent, '#0.##'), 1)
        , (' - ', format(prep.PrevPaidPercent, '#0.##'), 2)
        , (' - ', format(prep.PrevDiscountAmount, '#0.##'), 3)
        , (' - ', format(prep.PrevPercentRecalcAmount, '#0.##'), 4)
        , (' + ', prep.ChargedPercentFormula, 5)
        , (' - ', format(prep.MidPeriodPercentRecalcAmount, '#0.##'), 6)
        , (' - ', format(prep.MidPeriodDiscountAmount, '#0.##'), 7)             
    ) Comp (op, val, ord)
    where Comp.val != '0'
        and not (prep.PrevDebtPercent = prep.PrevPaidPercent and prep.PrevPaidPercent > 0 and comp.ord in (1, 2))
    order by Comp.ord
    for json auto, without_array_wrapper
) fp (PercentFormula)
outer apply
(
    select Comp.op, Comp.val
    from
    (
        values
        (null, format(prep.PrevDebtFine, '#0.##'), 1)
        , (' - ', format(prep.PrevPaidFine, '#0.##'), 2)
        , (' + ', prep.ChargedFineFormula, 3)
    ) Comp (op, val, ord)
    where Comp.val != '0'
        and (prep.ChargedFineFormula != '0' or prep.PrevPaidFine != 0)
    order by Comp.ord
    for json auto, without_array_wrapper
) ff (FineFormula)

union all

select 
    null as PercentFormula
    , null as FineFormula
    , PaymentDate as Date
    , null as ChargedPercentFormula
    , null as ChargedFineFormula
    , null as CalculatedChargedPercent
    , null as CalculatedChargedFine
    , null as ChargedPercent
    , null as ChargedFine
    , null as DiscountAmount
    , null as MidPeriodDiscountAmount
    , null as PercentRecalcAmount
    , null as MidPeriodPercentRecalcAmount
    , null as Errors
    , PaymentSource as PaymentSources
    , -Amount as DebtAmount
    , null as DebtPercent
    , null as DebtFine
    , null as DebtCommission
    , null as TotalDebt
    , null as PaidAmount
    , null as PaidPercent
    , null as PaidFine
    , null as PaidCommission
    , null as PaidProlong
    , Amount as TotalPaid
    , null as PrevDebtPercent
    , null as PrevDebtFine
    , null as PrevDiscountAmount
    , null as PrevPercentRecalcAmount
    , null as PrevPaidPercent
    , null as PrevPaidFine
from payments
where PaymentDirection = 1
/
/*
Вопросы:
1. скидку, которая произошла в дату платежа показываем где?
    Пример: 803974
2. скидку, которая произошла вне даты платежа показываем где?
    Пример: 415747
3. где показываем перерасчеты процентов? они происходят текущим днем, но в 00:00:01, а не в 00:00:00
    Пример: 442649
4. Нужно ли генерить строку для даты по договору? Сейчас смотрим только на проведенные платежи + текущая дата для незакрытых
Скидку и все перерасчеты показывать в дату платежа в строке начисленных процентов?
Типа, начислено - это все, что нужно погасить клиенту
5. Найти перерасчеты процентов, которые происходили вне даты платежа
Отдельная строка (Скидки, Перерасчеты) по аналогии с Погашение
*/

--/
--select top 10 cb.ProductId
--from bi.CreditBalance cb
--inner join prd.vw_Product p on p.Productid = cb.ProductId
--    and p.Status > 2
--    and p.Status != 5
--where cb.InfoType = 'payment'
--    and cb.DateOperation >= '20190401'
--    and cb.TotalPercent > 0
--    and cb.TotalAmount = 0
--order by cb.ProductId desc
/

select *
from prd.LongTermSchedule
where ProductId = 771354

