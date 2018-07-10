drop table if exists #Indicators
;

drop table if exists #col
;

drop table if exists #pay
;

drop table if exists #days
;

drop table if exists #colWorkDays
;

drop table if exists #Portfolio
;

declare
    @dateFrom date = '20180401'
    ,@dateTo date = '20180525'
;

declare
    @Green nvarchar(7) = '#68CE0C'
    ,@LightGreen nvarchar(7) = '#B5F779'
    ,@Yellow nvarchar(7) = '#F1F892'
    ,@Orange nvarchar(7) = '#ED6C49'
    ,@Pink nvarchar(7) = '#EB4B4B'
    ,@Red nvarchar(7) = '#E62222'
;

declare @Indicators nvarchar(max)
;

set @Indicators = 
(
    select *
    from (
        values 
            (null, 'TotalPaidPercent', 1.0, null, @Green)
            ,(null, 'TotalPaidPercent', 0.83, 1.0, @LightGreen)
            ,(null, 'TotalPaidPercent', 0.67, 0.83, @Yellow)
            ,(null, 'TotalPaidPercent', 0.51, 0.67, @Orange)
            ,(null, 'TotalPaidPercent', 0.35, 0.51, @Pink)
            ,(null, 'TotalPaidPercent', null, 0.35, @Red)
            
            ,('B', 'TotalPaid', 550000.0, null, null)
            ,('C', 'TotalPaid', 300000.0, null, null)
            
            ,('B', 'AveragePortfolio', null, 3800000, @Green)
            ,('B', 'AveragePortfolio', 3800000, 4200000, @LightGreen)
            ,('B', 'AveragePortfolio', 4200000, 4500000, @Yellow)
            ,('B', 'AveragePortfolio', 4500000, 4900000, @Orange)
            ,('B', 'AveragePortfolio', 4900000, null, @Red)
            
            ,('C', 'AveragePortfolio', null, 11200000, @Green)
            ,('C', 'AveragePortfolio', 11200000, 12200000, @LightGreen)
            ,('C', 'AveragePortfolio', 12200000, 13000000, @Yellow)
            ,('C', 'AveragePortfolio', 13000000, 14000000, @Orange)
            ,('C', 'AveragePortfolio', 14000000, null, @Red)        
             
            ,(null, 'DefaultRange', null, 1.0 / 6 * 1, @Red)
            ,(null, 'DefaultRange', 1.0 / 6 * 1, 1.0 / 6 * 2, @Pink)
            ,(null, 'DefaultRange', 1.0 / 6 * 2, 1.0 / 6 * 3, @Orange)
            ,(null, 'DefaultRange', 1.0 / 6 * 3, 1.0 / 6 * 4, @Yellow)
            ,(null, 'DefaultRange', 1.0 / 6 * 4, 1.0 / 6 * 5, @LightGreen)
            ,(null, 'DefaultRange', 1.0 / 6 * 5, null, @Green)
        ) as a(GroupName, Indicator, ValueFrom, ValueTo, Color)
    for json auto, INCLUDE_NULL_VALUES
)
;
exec bi.sp_CollectionStats @dateFrom, @dateTo, @Indicators
/

alter procedure bi.sp_CollectionStats(@dateFrom date, @dateTo date, @Indicators nvarchar(max)) as 

begin

set @dateTo = eomonth(@dateTo)
;

declare 
    @TotalDaysCount int = datediff(d, @dateFrom, @dateTo) + 1
    ,@RealDaysCount int = datediff(d, @dateFrom, case when getdate() < @dateTo then getdate() else dateadd(d, 1, @dateTo) end)
;

declare @MonthCount int = datediff(m, @DateFrom,  @DateTo) + 1

create table #Portfolio
(
    Date date
    ,CollectorId uniqueidentifier
    ,CollectorLogin nvarchar(100)
    ,CollectorName nvarchar(100)
    ,CollectorGroup nvarchar(100)
    ,CollectorGroupName nvarchar(100)
    ,Portfolio numeric(20,2)
)

insert into #Portfolio(Date, CollectorId, Portfolio)
exec [Col].[tf_AvgPortfolio] @DateFrom, @DateTo
;

select *
into #Indicators
from openjson(@Indicators, '$')
with
    (
        GroupName nvarchar(10) '$.GroupName'
        ,Indicator nvarchar(255) '$.Indicator'
        ,ValueFrom numeric(20, 6) '$.ValueFrom'
        ,ValueTo numeric(20, 6) '$.ValueTo'
        ,Color nvarchar(7) '$.Color'
    )
    
select top (@RealDaysCount)
    dateadd(d, row_number() over (order by name) - 1, @dateFrom) as dt1
    ,dateadd(d, row_number() over (order by name), @dateFrom) as dt2
into #days
from sys.sysobjects
;

select
    op.ProductId
    ,op.ClientId
    ,op.OverdueStart
    ,op.CollectorId
    ,op.ActiveAssign
    ,op.AssignDate
    ,op.LastDayWasAssigned
    ,case 
        when u.username = 'FakeCollectorTechnical' then 'A'
        when u.username = 'FakeCollectorPS' then 'D'
        when u.username = 'FakeCollectorOSV' then 'E'
        when u.username = 'FakeCollectorUndistributedODV' then 'F'
        when u.username = 'FakeCollectorUndistributedGTS' then 'G'
        when min(datediff(d, op.OverdueStart, op.AssignDate) + 1) over (partition by op.CollectorId) >= 70 then 'C'
        else 'B'
    end as CollectorGroup
    ,u.UserName as CollectorLogin
    ,uc.ClaimValue as CollectorName
into #col
from col.tf_op(@dateFrom, eomonth(@dateTo)) op
inner join sts.users u on u.id = op.CollectorId
left join sts.UserClaims uc on uc.userid = op.CollectorId
    and uc.ClaimType = 'name'
;

update p set
    p.CollectorGroup = c.CollectorGroup
    ,p.CollectorGroupName = c.CollectorGroupName
    ,p.CollectorLogin = c.CollectorLogin
    ,p.CollectorName = c.CollectorName
    ,p.Portfolio = p.Portfolio * -1
from #Portfolio p
outer apply
(
    select top 1 
        c.CollectorGroup
        ,cg.GroupName as CollectorGroupName
        ,c.CollectorLogin
        ,c.CollectorName
    from #col c
    inner join col.vw_cg cg on cg.GroupId = c.CollectorGroup
    where c.CollectorId = p.CollectorId
) c

select
    col.CollectorId
    ,col.CollectorGroup
    ,count(distinct d.dt1) as days
into #colWorkDays
from #days d
left join #col col on col.AssignDate < d.dt2
    and col.LastDayWasAssigned >= d.dt1
group by col.CollectorId, col.CollectorGroup
;

select
    cb.ProductId
    ,col.ClientId
    ,col.CollectorId
    ,cb.DateOperation
    ,cb.TotalAmount
    ,cb.TotalDebt
    ,col.CollectorGroup
    ,case when col.CollectorGroup = 'B' then 1 else 0 end as ExcludeAmountPaid
into #pay
from bi.CreditBalance cb
inner join #col col on col.ProductId = cb.ProductId
    and cb.DateOperation between (select max(dt) from (values (@dateFrom), (col.AssignDate)) v(dt)) 
                                and (select min(dt) from (values (dateadd(d, 1, eomonth(@dateTo))), (col.LastDayWasAssigned)) v(dt))
    and cb.InfoType = 'payment'
;

with Pay as 
(
    select
        cwd.CollectorId
        ,cwd.days as CollectorHadPortfolioDays
        ,tp.ValueFrom * @MonthCount as PeriodPlanned
        ,sum(pay.TotalAmount) as TotalAmountPaid
        ,sum(pay.TotalDebt - pay.TotalAmount) as TotalOtherPaid
        ,sum(pay.TotalDebt - pay.ExcludeAmountPaid * pay.TotalAmount ) as TotalPaid
        ,sum(pay.TotalDebt - pay.ExcludeAmountPaid * pay.TotalAmount ) / @RealDaysCount * @TotalDaysCount as ForecastPaid
        ,count(distinct ClientId) * 1.0 / cwd.days as AvgClientPay
        ,row_number() over (partition by cwd.CollectorGroup order by (count(distinct ClientId) * 1.0 / cwd.days)) * 1.0 /
                        sum(count(distinct 1)) over (partition by cwd.CollectorGroup) as AvgClientPayProc                         
        ,sum(pay.TotalDebt - pay.ExcludeAmountPaid * pay.TotalAmount ) / count(distinct ClientId) as AvgClientPaymentSum
        ,row_number() over (partition by cwd.CollectorGroup order by (sum(pay.TotalDebt - pay.ExcludeAmountPaid * pay.TotalAmount ) / count(distinct ClientId))) * 1.0 / 
                        sum(count(distinct 1)) over (partition by cwd.CollectorGroup) as AvgClientPaymentSumProc
        ,count(distinct ClientId) as TotalClientsPaid
        ,row_number() over (partition by cwd.CollectorGroup order by count(distinct ClientId)) * 1.0 / 
                        sum(count(distinct 1)) over (partition by cwd.CollectorGroup) as TotalClientsPaidProc
        ,sum(count(distinct 1)) over (partition by cwd.CollectorGroup) as CollectorsInGroup
    from #colWorkDays cwd
    left join #pay pay on cwd.CollectorId = pay.CollectorId
    left join #Indicators tp on tp.GroupName = cwd.CollectorGroup
        and tp.Indicator = 'TotalPaid'
    group by cwd.CollectorId, cwd.days, cwd.CollectorGroup, tp.ValueFrom
)

,AvgPortfolio as 
(
    -- Берем средний портфель по каждому месяцу и суммируем
    select distinct
        CollectorId
        ,CollectorGroup
        ,CollectorGroupName
        ,CollectorLogin
        ,CollectorName
        ,sum(avg(Portfolio)) over (partition by CollectorId) as AvgPortfolio
    from #Portfolio
    group by CollectorId, CollectorGroup, CollectorLogin
        ,datepart(m, date), CollectorName, CollectorGroupName
)

,pre as 
(
    select
        apo.CollectorLogin
        ,apo.CollectorGroup
        ,apo.CollectorGroupName
        ,apo.CollectorName
        ,p.CollectorHadPortfolioDays
        ,p.PeriodPlanned
        ,p.TotalAmountPaid
        ,p.TotalOtherPaid
        ,p.TotalPaid
        ,p.ForecastPaid
        ,p.AvgClientPay
        ,p.AvgClientPayProc                         
        ,p.AvgClientPaymentSum
        ,p.AvgClientPaymentSumProc
        ,p.TotalClientsPaid
        ,p.TotalClientsPaidProc
        ,p.CollectorsInGroup
        ,pc.Color as TotalPaidColor
        ,fc.Color as ForecastPaidColor
        ,apo.AvgPortfolio
        ,ap.Color as AveragePortfolioColor
        ,cp.Color as AvgClientPayColor
        ,cps.Color as AvgClientPaymentSumColor
        ,tcp.Color as TotalClientsPaidColor
        ,@RealDaysCount as DaysInPeriod
        ,case when CollectorHadPortfolioDays < @RealDaysCount then '#ED6C49' end as CollectorColor
        ,isnull(p.TotalPaid / nullif(apo.AvgPortfolio, 0), 0) as Efficiency
        ,row_number() over (partition by apo.CollectorGroup order by isnull(p.TotalPaid / nullif(apo.AvgPortfolio, 0), 0)) * 1.0 / CollectorsInGroup as EfficiencyProc
    from AvgPortfolio apo
    left join Pay p on p.CollectorId = apo.CollectorId
    left join #Indicators pc on pc.Indicator = 'TotalPaidPercent'
        and (p.TotalPaid / p.PeriodPlanned >= pc.ValueFrom or pc.ValueFrom is null)
        and (p.TotalPaid / p.PeriodPlanned < pc.ValueTo or pc.ValueTo is null)
    left join #Indicators fc on fc.Indicator = 'TotalPaidPercent'
        and (p.ForecastPaid / p.PeriodPlanned >= fc.ValueFrom or fc.ValueFrom is null)
        and (p.ForecastPaid / p.PeriodPlanned < fc.ValueTo or fc.ValueTo is null)
    left join #Indicators ap on ap.GroupName = apo.CollectorGroup
        and ap.Indicator = 'AveragePortfolio'
        and (apo.AvgPortfolio >= ap.ValueFrom * @MonthCount or ap.ValueFrom is null)
        and (apo.AvgPortfolio < ap.ValueTo * @MonthCount or ap.ValueTo is null)  
    left join #Indicators cp on cp.Indicator = 'DefaultRange'
        and (p.AvgClientPayProc >= cp.ValueFrom or cp.ValueFrom is null)
        and (p.AvgClientPayProc < cp.ValueTo or cp.ValueTo is null)
        and apo.CollectorGroup in ('B', 'C')
    left join #Indicators cps on cps.Indicator = 'DefaultRange'
        and (p.AvgClientPaymentSumProc >= cps.ValueFrom or cps.ValueFrom is null)
        and (p.AvgClientPaymentSumProc < cps.ValueTo or cps.ValueTo is null)
        and apo.CollectorGroup in ('B', 'C')
    left join #Indicators tcp on tcp.Indicator = 'DefaultRange'
        and (p.TotalClientsPaidProc >= tcp.ValueFrom or tcp.ValueFrom is null)
        and (p.TotalClientsPaidProc < tcp.ValueTo or tcp.ValueTo is null)  
        and apo.CollectorGroup in ('B', 'C')
)

select
    p.*
    ,ef.color as EfficiencyColor
from pre p
left join #Indicators ef on ef.Indicator = 'DefaultRange'
    and (p.EfficiencyProc >= ef.ValueFrom or ef.ValueFrom is null)
    and (p.EfficiencyProc < ef.ValueTo or ef.ValueTo is null)
end

--    and p.CollectorGroup in ('B', 'C')
--where p.CollectorGroup in (@CollectorGroup)
