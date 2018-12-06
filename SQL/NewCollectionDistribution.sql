create table bi.CollectorGroupMap
(
    CollectorGroupNum int
    , CollectorGroup varchar
)
;

INSERT INTO bi.CollectorGroupMap (CollectorGroupNum,CollectorGroup) VALUES(8000,'G')
GO
INSERT INTO bi.CollectorGroupMap (CollectorGroupNum,CollectorGroup) VALUES(7000,'F')
GO
INSERT INTO bi.CollectorGroupMap (CollectorGroupNum,CollectorGroup) VALUES(6,'E')
GO
INSERT INTO bi.CollectorGroupMap (CollectorGroupNum,CollectorGroup) VALUES(5,'D')
GO
INSERT INTO bi.CollectorGroupMap (CollectorGroupNum,CollectorGroup) VALUES(4,'C')
GO
INSERT INTO bi.CollectorGroupMap (CollectorGroupNum,CollectorGroup) VALUES(3,'B')
GO
INSERT INTO bi.CollectorGroupMap (CollectorGroupNum,CollectorGroup) VALUES(1,'A')
GO

alter table bi.CollectorGroupAgentHistory add CollectorGroupNum int 
;

update cgah set cgah.CollectorGroupNum = cgm.CollectorGroupNum
from bi.CollectorGroupAgentHistory cgah
inner join bi.CollectorGroupMap cgm on cgm.CollectorGroup = cgah.CollectorGroup
;

alter table bi.CollectorGroupHistory add CollectorGroupNum int 
;

update cgh set cgh.CollectorGroupNum = cgm.CollectorGroupNum
from bi.CollectorGroupHistory cgh
inner join bi.CollectorGroupMap cgm on cgm.CollectorGroup = cgh.CollectorGroup
;

alter table bi.CollectorGroupHistory add DayCollectorGroupNum int 
;

update cgh set cgh.DayCollectorGroupNum = cgm.CollectorGroupNum
from bi.CollectorGroupHistory cgh
inner join bi.CollectorGroupMap cgm on cgm.CollectorGroup = cgh.DayCollectorGroup
;

alter table bi.OldCollectorAssigns add CollectorGroupNum int 
;

update oca set oca.CollectorGroupNum = cgm.CollectorGroupNum
from bi.OldCollectorAssigns oca
inner join bi.CollectorGroupMap cgm on cgm.CollectorGroup = oca.CollectorGroup
;

ALTER VIEW Col.vw_cg as 
select  
    cg.Name as GroupId
    ,case cg.Name
        when 'A' then N'Буффер ТП'
        when 'B' then N'ОДВ'
        when 'C' then N'ГТС'
        when 'D' then N'Буффер ПС'
        when 'E' then N'Буффер ОСВ'
        when 'F' then N'Нераспр. ОДВ'
        when 'G' then N'Нераспр. ГТС'
    end as GroupName
    ,cg.STOverdueDaysMin
    ,cg.STOverdueDaysMax
    ,cg.STReassignOverdueDays
    ,cg.LTOverdueDaysMin
    ,cg.LTOverdueDaysMax
    ,cg.LTReassignOverdueDays
    ,cgm.CollectorGroupNum
from col.CollectorSetting
cross apply openjson(ValueSnapshot, '$') 
with 
    (
        Name nvarchar(10) '$.Name'
        ,STOverdueDaysMin int '$.Rules.ShortTermCredit.MinOverdueDays'
        ,STOverdueDaysMax int '$.Rules.ShortTermCredit.MaxOverdueDays'
        ,STReassignOverdueDays int '$.Rules.ShortTermCredit.ReassignOverdueDays'
        ,LTOverdueDaysMin int '$.Rules.LongTermCredit.MinOverdueDays'
        ,LTOverdueDaysMax int '$.Rules.LongTermCredit.MaxOverdueDays'
        ,LTReassignOverdueDays int '$.Rules.LongTermCredit.ReassignOverdueDays'
    ) as cg
inner join bi.CollectorGroupMap cgm on cgm.CollectorGroup = cg.Name
where SettingType = 1
GO

ALTER VIEW bi.vw_CollectoAssignsPayments as 
select
    cast(op.OverdueProductId as nvarchar(100)) + ISNULL(':' + CAST(cb.id as nvarchar(100)), N'') as id
    , op.CollectorId
    , op.ProductId
    , op.ClientId
    , cast(op.OverdueStart as date) as OverdueStart
    , cast(op.AssignDate as date) as AssignDate
    , cast(op.LastDayWasAssigned as date) as LastDateWasAssigned
    , op.ActiveAssign
    , datepart(year, cb.DateOperation) as PaymentYearNum
    , datepart(month, cb.DateOperation) as PaymentMonthNum
    , cast(dateadd(m, datediff(m, 0, cb.DateOperation), 0) as date) as PaymentMonthStart
    , cast(cb.DateOperation as date) as PaymentDate
    , cb.TotalAmount as Amount
    , cb.TotalPercent as [Percent]
    , cb.Commission
    , cb.Prolong
    , cb.Fine
    , cb.TotalDebt as TotalPaid
    , datediff(d, op.OverdueStart, cb.DateOperation) + 1 as PaymentOverdueDay
    , datediff(d, op.AssignDate, cb.DateOperation) + 1 as PaymentAssignDay
    , case 
        when cb.id is not null 
        then op.clientid 
    end as ClientPaid
    ,case when op.ActiveAssign = 0 then 0 else datediff(d, op.OverdueStart, getdate()) + 1 end as OverdueDays
    ,case 
        when min(datediff(d, op.OverdueStart, op.AssignDate) + 1) over (partition by op.CollectorId, op.AssignDate) > 40 
        then 'C'
        else 'B'
    end as CollectorGroupAtAssignDaY
    ,case 
        when min(datediff(d, op.OverdueStart, op.AssignDate) + 1) over (partition by op.CollectorId, op.AssignDate) > 40 
        then 4
        else 3
    end as CollectorGroupNumAtAssignDaY
from Col.tf_op('19000101', getdate()) as op
left join col.CollectorGroup cg on cg.CollectorId = op.CollectorId
left outer join bi.CreditBalance as cb on cb.ProductId = op.ProductId 
    and cb.DateOperation between op.AssignDate and op.LastDayWasAssigned 
    and cb.InfoType = 'payment'
GO

CREATE or alter view bi.vw_CollectorGroupHistory as 
with cd as 
(
    select
        cpd.CollectorId
        ,cpd.Date
        ,min(cpd.OverdueDays) as MinOverdueDays
        ,sum(cpd.TotalDebt) as Portfolio
        ,sum(cpd.TotalPaid) as TotalPaid
        ,sum(cpd.AmountPaid) as AmountPaid
    from bi.CollectorPortfolioDetail cpd
    group by 
        cpd.CollectorId
        ,cpd.Date
)

,gr as 
(
    select
        cast(format(dt.Date, 'yyyyMM01') as date) as Mnth
        ,dt.Date
        ,dt.CollectorId
        ,case
            when u.UserName = 'FakeCollectorPS' then 'D'
            when u.UserName like 'FakeCollector%' then cg.name
            when dt.MinOverdueDays >= 75 and dt.Date >= '20180903' then 'D'
            when dt.MinOverdueDays >= 46 then 'C'
            else 'B'
        end as CollectorGroup
        ,case
            when u.UserName = 'FakeCollectorPS' then 5
            when u.UserName like 'FakeCollector%' then vw_cg.CollectorGroupNum
            when dt.MinOverdueDays >= 75 and dt.Date >= '20180903' then 5
            when dt.MinOverdueDays >= 46 then 4
            else 3
        end as CollectorGroupNum
        ,u.name as CollectorName
        ,u.Is_Enabled
    from cd dt
    left join sts.vw_admins u on u.id = dt.CollectorId
    left join col.CollectorGroup cg on cg.CollectorId = dt.CollectorId
    left join col.vw_cg on vw_cg.GroupId = cg.Name
)

,cm as 
(
    select distinct
        Mnth
        ,CollectorId
        ,CollectorName
        ,first_value(CollectorGroup) over (partition by CollectorId, Mnth order by Date desc) as CollectorGroup
        ,first_value(CollectorGroupNum) over (partition by CollectorId, Mnth order by Date desc) as CollectorGroupNum
    from gr
)
    
select
    gd.dt1 as Date
    ,cm.CollectorId
    ,cm.CollectorName
    ,cm.CollectorGroup
    ,cm.CollectorGroupNum
    ,cgm.GroupName as CollectorGroupName
    ,min(gr.Is_Enabled) over (partition by cm.CollectorId) as Is_Enabled
    ,case when cm.CollectorGroup != 'B' then 1 else 0 end as IncludePaidAmount
    ,gr.CollectorGroup as DayCollectorGroup
    ,gr.CollectorGroupNum as DayCollectorGroupNum
    ,cg.GroupName as DayCollectorGroupName
from cm
outer apply
(
    select dt1
    from bi.tf_gendate(cm.Mnth, eomonth(cm.Mnth))
) gd
left join gr on gr.Date = gd.dt1
    and gr.CollectorId = cm.CollectorId
left join col.vw_cg cgm on cgm.GroupId = cm.CollectorGroup
left join col.vw_cg cg on cg.GroupId = gr.CollectorGroup
where gd.dt1 <= cast(getdate() as date)
;

ALTER PROCEDURE [bi].[sp_RecreateCollectorGroupHistory] as 

    if not exists 
        (
            select 1
            from sys.tables t
            inner join sys.schemas s on s.schema_id = t.schema_id
            where s.name = 'bi'
                and t.name = 'CollectorGroupHistory'
        )
    begin
        CREATE TABLE [bi].[CollectorGroupHistory]  ( 
            [Date]                  date not NULL,
            [CollectorId]           uniqueidentifier NOT NULL,
            [CollectorName]         nvarchar(256) NULL,
            [CollectorGroup]        nvarchar(100) NULL,
            [CollectorGroupName]    nvarchar(100) NULL,
            [Is_Enabled]            nvarchar(10) NOT NULL,
            [IncludePaidAmount]     int NOT NULL ,
            [DayCollectorGroup]       nvarchar(100) NULL,
            [DayCollectorGroupName]   nvarchar(100) NULL
            )
        ;
        
        alter table bi.CollectorGroupHistory add primary key (CollectorId, Date)
        ;
    end
    
    delete 
    from [bi].[CollectorGroupHistory]
    where Date >= format(getdate(), 'yyyyMM01')
    ;
    
    insert [bi].[CollectorGroupHistory]
    (
        Date,CollectorId,CollectorName,CollectorGroup,CollectorGroupNum,CollectorGroupName,Is_Enabled,IncludePaidAmount,DayCollectorGroup,DayCollectorGroupNum,DayCollectorGroupName
    )
    select
        Date,CollectorId,CollectorName,CollectorGroup,CollectorGroupNum,CollectorGroupName,Is_Enabled,IncludePaidAmount,DayCollectorGroup,DayCollectorGroupNum,DayCollectorGroupName
    from bi.vw_CollectorGroupHistory
    where Date >= format(getdate(), 'yyyyMM01')


;


ALTER PROCEDURE bi.SP_CBI_CollectionStats(@dateFrom date, @dateTo date) as
begin
    /*
    declare 
        @dateFrom date = '20180501'
        ,@dateTo date = '20180801'
    ;
    */
    declare 
        @monthDiff int
    ;
    set language russian
    ;
    
    set @dateFrom = cast(format(@dateFrom, 'yyyyMM01') as date)
    ;
    
    set @dateTo = cast(format(@dateTo, 'yyyyMM01') as date)
    ;

    set @dateFrom = (select max(d) from (values (@dateFrom), ('20180301')) v(d))
    ;
    
    set @dateTo = (select min(d) from (values (eomonth(@dateTo)), (cast(getdate() as date))) v(d))
    ;

    drop table if exists #dates
    ;
    
    drop table if exists #AllProducts
    ;
    
    drop table if exists #crr
    ;
    
    drop table if exists #prdInfo
    ;
    
    drop table if exists #tech
    ;

    drop table if exists #techCallers
    ;

    drop table if exists #MoneyStats
    ;
    
    drop table if exists #ClientsStats
    ;
        
    select
        dt1 as dt
    into #dates
    from bi.tf_gendate(@dateFrom, @dateTo)
    ;

    select
        crr.ClientId
        ,crr.CreatedOn
        ,isnull(crr.Score, left( stuff( json_value (crr.ResultSnapshot, '$[2].Messages[0].Message'), 1, 37, ''), 5)) as Score
    into #crr
    from cr.CreditRobotResult crr
    ;
    
    create index IX_crr_ClientId_CreatedOn on #crr(ClientId, CreatedOn)
    ;

    select *
    into #AllProducts
    from
    (
        select
            op.ProductId
            ,op.ClientId
            ,op.DateStarted as StartedOn
        from bi.OldProducts op
        where (op.DatePaid < '20180225' or op.DatePaid is null)
            and op.DateStarted < '20180225'
            and not exists 
                (
                    select 1 from prd.product p
                    where p.id = op.ProductId
                )
            
        union
        
        select
            p.ProductId
            ,p.ClientId
            ,p.StartedOn
        from prd.vw_product p
        where p.status > 2
    )  AllProducts
    ;
    
    select
        p.ProductId
        ,p.ClientId
        ,nullif(case when p.StartedOn >= '20180601' then crr.Score end, 0) as Score
        ,case when num.cnt = 0 then 'NewClient' else 'OldClient' end as ClientType
        ,p.ProductType
        ,c.PhoneNumber
    into #prdInfo
    from prd.vw_Product p
    inner join Client.vw_client c on c.ClientId = p.ClientId
    outer apply
    (
        select top 1 crr.Score
        from #crr crr
        where crr.ClientId  = p.ClientId
            and crr.CreatedOn < p.CreatedOn 
        order by crr.CreatedOn desc
    ) crr
    outer apply
    (
        select count(*) as cnt
        from #AllProducts ap
        where ap.ClientId = p.ClientId
            and ap.StartedOn < p.StartedOn
            
    ) num
    where p.ProductId in (select productid from bi.CollectorPortfolioDetail cpd  where cpd.Date between @dateFrom and @dateTo)
    ;
    
    alter table #prdInfo add primary key (ProductId)
    ;
    
    select
        dateadd(month, datediff(month, 0, cpd.Date), 0) as Mnth
        ,cpd.Date
        ,p.PhoneNumber
    into #tech
    from bi.CollectorPortfolioDetail cpd
    inner join #prdInfo p on p.ProductId = cpd.ProductId 
    inner join sts.users u on u.id = cpd.CollectorId
        and u.UserName = 'FakeCollectorTechnical'
     
    create clustered index IX_tech_Date_PhoneNumber on #tech(Date, PhoneNumber)
    
    select
        t.Mnth
        ,count(distinct cc.CollectorName) as UniqueTechCallers
    into #techCallers
    from #tech t 
    inner join bi.vw_CollectorCalls cc on cast(cc.CallStart as date) = t.Date
        and cc.TruePhoneNumber = t.PhoneNumber
    group by t.Mnth
    ;

    select 
        dateadd(month, datediff(month, 0, cpd.Date), 0) as Mnth
        ,avg(pin.Score) as AverageScore
        ,count(case when pin.ClientType = 'NewClient' then 1 end) * 1.0 / count(*) as NewClientPart
        ,count(case when pin.ClientType = 'OldClient' then 1 end) * 1.0 / count(*) as OldClientPart
        ,count(case when pin.ProductType = 1 then 1 end) * 1.0 / count(*) as STPart
        ,count(case when pin.ProductType = 2 then 1 end) * 1.0 / count(*) as LTPart
--        ,sum(cpd.AmountPaid) as AmountPaid
--        ,sum(cpd.PercentPaid + cpd.Commissionpaid + cpd.FinePaid + cpd.ProlongPaid) as OtherPaid
    into #ClientsStats
    from bi.CollectorPortfolioDetail cpd
    inner join #prdInfo pin on pin.ProductId = cpd.ProductId
    where cpd.Date between @dateFrom and @dateTo
    group by dateadd(month, datediff(month, 0, cpd.Date), 0)
    ;

    with d as 
    (
        select
            dateadd(month, datediff(month, 0, cpd.Date), 0) as Mnth
            ,cpd.CollectorId
            ,cgh.DayCollectorGroupNum as CollectorGroupNum
            ,sum(cpd.ActiveAmountDebt + cpd.OverdueAmountDebt + cpd.ActivePercentDebt + cpd.OverduePercentDebt + cpd.FineDebt + cpd.CommissionDebt) as PortfolioSum
            ,count(*) as PortfolioCount
            ,sum(cpd.AmountPaid) as AmountPaid
            ,sum(cpd.PercentPaid + cpd.Commissionpaid + cpd.FinePaid + cpd.ProlongPaid) as OtherPaid
        from bi.CollectorPortfolioDetail cpd
        inner join bi.CollectorGroupHistory cgh on cgh.CollectorId = cpd.CollectorId
            and cgh.Date = cpd.Date
        where cpd.Date between @dateFrom and @dateTo
        group by dateadd(month, datediff(month, 0, cpd.Date), 0), cpd.CollectorId, cgh.DayCollectorGroupNum
    )
    
    select
        d.Mnth
        ,avg(case when d.CollectorGroupNum = '3' then d.PortfolioSum end) as AvgODVPortfolioSum
        ,avg(case when d.CollectorGroupNum = '4' then d.PortfolioSum end) as AvgGTSPortfolioSum
        ,avg(case when d.CollectorGroupNum = '3' then d.PortfolioCount end) as AvgODVPortfolioCount
        ,avg(case when d.CollectorGroupNum = '4' then d.PortfolioCount end) as AvgGTSPortfolioCount
        ,count(distinct case when d.CollectorGroupNum = '3' then d.CollectorId end) as UniqueODVEmployees
        ,count(distinct case when d.CollectorGroupNum = '4' then d.CollectorId end) as UniqueGTSEmployees
        ,sum(case when d.CollectorGroupNum = '3' then d.AmountPaid end) as ODVAmountPaid
        ,sum(case when d.CollectorGroupNum = '4' then d.AmountPaid end) as GTSAmountPaid
        ,sum(case when d.CollectorGroupNum = '3' then d.OtherPaid end) as ODVOtherPaid
        ,sum(case when d.CollectorGroupNum = '4' then d.OtherPaid end) as GTSOtherPaid
    into #MoneyStats
    from d
    group by d.Mnth
    ;
    
    with promises as 
    (
        select
            dateadd(month, datediff(month, 0, DatePromises), 0) as Mnth
            ,count(*) as PromisesCnt
        from col.InternalInteraction
        where DatePromises >= '20180301'
        group by dateadd(month, datediff(month, 0, DatePromises), 0)
    )
    
    select
        cs.Mnth
        ,ms.AvgODVPortfolioSum
        ,ms.AvgGTSPortfolioSum
        ,ms.AvgODVPortfolioCount
        ,ms.AvgGTSPortfolioCount
        ,ms.UniqueODVEmployees
        ,ms.UniqueGTSEmployees
        ,ts.UniqueTechCallers
        ,ms.ODVAmountPaid
        ,ms.GTSAmountPaid
        ,ms.ODVOtherPaid
        ,ms.GTSOtherPaid
        ,cs.AverageScore
        ,cs.STPart
        ,cs.LTPart
        ,cs.NewClientPart
        ,cs.OldClientPart
        ,p.PromisesCnt
    from #ClientsStats cs
    inner join #MoneyStats ms on ms.Mnth = cs.Mnth
    left join #techCallers ts on ts.Mnth = cs.Mnth
    left join promises p on p.Mnth = cs.Mnth
end
GO


create or ALTER FUNCTION Col.tf_op2(@DateFrom datetime2, @DateTo datetime2)
returns table as
return
(
with op as 
(
    select
        cph.Id as OverdueProductId
        , cph.ToCollectorId as CollectorId
        , cph.ToGroupId as CollectorGroupId
        , p.ClientId
        , cp.ProductId
        , cast(cast(cph.CreatedOn as date) as datetime2) as AssignDate
        , dateadd(ms, -1, cast(cast(cph.EndDate as date) as datetime2)) as LastDayWasAssigned
        , iif(cph.EndDate is null, 1, 0) as ActiveAssign
    from Collector.Product cp
    inner join Collector.ProductHistory cph on cph.ProductId = cp.Id
    inner join prd.Product p on p.id = cp.ProductId
    where 1=1
        and (cast(cph.CreatedOn as date) != cast(cph.EndDate as date) or cph.EndDate is null)
        and not exists 
            (
                select 1 from Collector.ProductHistory cph2
                where cph2.ProductId = cph.ProductId
                    and cast(cph2.CreatedOn as date) = cast(cph.CreatedOn as date)
                        and cph2.id > cph.id
            )
        and cast(cph.CreatedOn as date) <= cast(@DateTo as date)
        and (cph.EndDate is null or cast(cph.EndDate as date) >= @DateFrom)
)

select
    op.OverdueProductId
    , op.CollectorId
    , op.CollectorGroupId
    , op.ClientId
    , op.ProductId
    , ls.OverdueStart
    , op.AssignDate
    , case 
        when cast(op.LastDayWasAssigned as date) = cast(lead(op.AssignDate) over (partition by op.ProductId order by op.AssignDate, op.LastDayWasAssigned) as date)
        then dateadd(d, -1, op.LastDayWasAssigned)
        else op.LastDayWasAssigned
    end as LastDayWasAssigned
    , lead(op.AssignDate) over (partition by op.ProductId order by op.AssignDate, op.LastDayWasAssigned) as NextAssign
    , op.ActiveAssign
    , lag(op.CollectorId) over (partition by op.ProductId order by op.AssignDate) as PrevCollectorId
from op
outer apply
(
    select top 1 
        sl.status
        ,sl.StartedOn as OverdueStart
    from prd.vw_statusLog sl
    where sl.ProductId = op.ProductId
        and sl.StartedOn <= op.AssignDate
    order by sl.StartedOn desc
) as ls
where ls.status = 4
)
go


create or ALTER PROCEDURE bi.sp_CollectionPayments1(@dateFrom date, @dateTo date, @Indicators nvarchar(max))
as 
begin

set @dateTo = eomonth(@dateTo)
;

declare 
    @TotalDaysCount int = datediff(d, @dateFrom, @dateTo) + 1
    ,@RealDaysCount int = datediff(d, @dateFrom, case when getdate() < @dateTo then getdate() else dateadd(d, 1, @dateTo) end)
;

drop table if exists #days
;

drop table if exists #col
;

drop table if exists #pay
;

drop table if exists #Indicators
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
        ,CollectorGroupNum nvarchar(10) '$.CollectorGroupNum'
    )
;

select top (@TotalDaysCount)
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
    ,u.UserName as CollectorLogin
    ,uc.ClaimValue as CollectorName
    ,op.AssignDate
    ,op.LastDayWasAssigned
    ,cast(cg.CollectorGroupNum as nvarchar(10)) as CollectorGroupNum
into #col
from col.tf_op(@dateFrom, @dateTo) op
inner join sts.users u on u.id = op.CollectorId
left join sts.UserClaims uc on uc.userid = op.collectorid
    and uc.ClaimType = 'name'
left join bi.CollectorGroupHistory cg on cg.CollectorId = op.CollectorId
    and cg.Date = op.AssignDate
;

select
    col.CollectorId
    ,col.CollectorGroupNum
    ,cast(cb.DateOperation as date) as PayDay
    ,sum(cb.TotalDebt - case when col.CollectorGroupNum = '3' then cb.TotalAmount else 0 end) as PaySum
into #pay
from #col col
inner join bi.CreditBalance cb on cb.ProductId = col.ProductId
    and cb.DateOperation >= col.AssignDate
    and cb.DateOperation <= col.LastDayWasAssigned
    and cast(cb.DateOperation as date) between @dateFrom and @dateTo
    and cb.InfoType = 'payment'
group by 
    col.CollectorId
    ,cast(cb.DateOperation as date)
    ,col.CollectorGroupNum
;

set language russian

select
    d.dt1
    ,datename(month, d.dt1) + ' ' + cast(datepart(year, d.dt1) as nvarchar(4)) as MonthName
    ,cl.CollectorLogin
    ,cl.CollectorName
    ,cl.CollectorGroupNum as CollectorGroup
    ,isnull(p.PaySum, 0) as PaySum
    ,i.Color as PaySumColor
    ,cg.GroupName as CollectorGroupName 
from #days d
cross join (select distinct CollectorId, CollectorLogin, CollectorGroupNum, CollectorName from #col) cl
left join #pay p on d.dt1 = p.PayDay
    and p.Collectorid = cl.CollectorId
    and p.CollectorGroupNum = cl.CollectorGroupNum
left join #Indicators i on i.CollectorGroupNum = cl.CollectorGroupNum
    and (isnull(p.PaySum, 0) >= i.ValueFrom or i.ValueFrom is null)
    and (isnull(p.PaySum, 0) < i.ValueTo or i.ValueTo is null)
    and d.dt1 < cast(getdate() as date)
left join col.vw_cg cg on cg.CollectorGroupNum = cl.CollectorGroupNum
end

GO



create or ALTER PROCEDURE bi.sp_CollectionStats1(@dateFrom date, @dateTo date, @Indicators nvarchar(max)) as 

begin
    /*
    declare
        @dateFrom date = '20180701'
        ,@dateTo date = '20180821'
    ;
    */
    
    set @dateFrom = format(@dateFrom, 'yyyyMM01')
    ;
    
    set @dateTo = eomonth(@dateTo)
    ;
    -- Количество дней в месяце
    declare
        @TotalDaysCount int = datediff(d, @dateFrom, @dateTo) + 1
    ;
    
    set @dateTo = (select min(dt) from (values (cast(getdate() as date)), (@dateTo)) as d(dt))
    ;
    
    declare @datePayTo date = (select min(dt) from (values (cast(getdate() - 1 as date)), (@dateTo)) as d(dt))
    ;
    
    declare @daysLeftInPeriod int = datediff(d, @dateTo, eomonth(@dateTo)) + case when cast(getdate() as date) <= eomonth(@dateTo) then 1 else 0 end
    ;
    
    -- Количество дней, когда у коллектора мог быть портфель (портфели распределяются в начале дня)
    declare
        @RealDaysCount int = datediff(d, @dateFrom, @dateTo) + 1
    ;
    
    declare @MonthCount int = datediff(m, @DateFrom,  @DateTo) + 1
    ;
    
    drop table if exists #Portfolio
    ;
    
    drop table if exists #Payments
    ;
    
    drop table if exists #cgh
    ;
    
    drop table if exists #Indicators
    ;
    
    drop table if exists #effM3
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
        ,CollectorGroupNum nvarchar(10) '$.CollectorGroupNum'
    )
    
    select
        pd.Date
        ,pd.CollectorId
        ,sum(pd.TotalDebt) as Portfolio
        ,count(*) as ClientCount
    into #Portfolio
    from bi.CollectorPortfolioDetail pd
    where Date between @DateFrom and @DateTo
    group by
        pd.Date
        ,pd.CollectorId
    ;
    
    create index IX_Portfolio_Date_CollectorId on #Portfolio(CollectorId, Date)
    ;
    
    select
        pd.CollectorId
        ,pd.Date
        ,pd.ClientId
        ,pd.AmountPaid
        ,pd.TotalPaid - pd.AmountPaid as OtherPaid
    into #Payments
    from bi.CollectorPortfolioDetail pd
    where pd.Date between @DateFrom and @DateTo
        and pd.TotalPaid > 0
    ;
    
    create index IX_Payments_Date_CollectorId on  #Payments(CollectorId, Date)
    ;
    
    select
        CollectorId
        ,CollectorName
        ,Date
        ,cast(CollectorGroupNum as nvarchar(10)) as CollectorGroupNum
        ,CollectorGroupName
        ,cast(lag(CollectorGroupNum) over (partition by CollectorId order by Date) as nvarchar(10))  as PrevCollectorGroup
    into #cgh
    from bi.CollectorGroupHistory cgh
    ;
    
    create clustered index IX_cgh_Date_CollectorId on #cgh (Date, CollectorId)
    ;

    with effPre as 
    (
        select 
            cpd.Date
            ,cpd.CollectorId
            ,datediff(month, format(cpd.Date, 'yyyyMM01'), @dateFrom) as MnthNum
            ,sum(cpd.TotalDebt) as Portfolio
            ,sum(cpd.TotalPaid - (~cast(cgh.IncludePaidAmount as bit)) * cpd.AmountPaid) as Paid
        from bi.CollectorPortfolioDetail cpd
        inner join bi.CollectorGroupHistory cgh on cgh.CollectorId = cpd.CollectorId
            and cgh.Date = cpd.Date
        where cpd.Date between dateadd(month, -3, @dateFrom) and dateadd(d, -1, @dateFrom)
        group by cpd.Date, cpd.CollectorId
    )
    
    select
        CollectorId
        ,sum(case when MnthNum = 3 then Paid end) / avg(case when MnthNum = 3 then Portfolio end) as M3
        ,sum(case when MnthNum = 2 then Paid end) / avg(case when MnthNum = 2 then Portfolio end) as M2
        ,sum(case when MnthNum = 1 then Paid end) / avg(case when MnthNum = 1 then Portfolio end) as M1
    into #effM3
    from effPre
    group by CollectorId
    ;

    with pay as
    (
        select
            po.CollectorId
            ,count(distinct po.Date) as CollectorHadPortfolioDays
            ,tp.ValueFrom * count(distinct format(po.Date, 'yyyyMM01')) as PeriodPlanned
            ,count(distinct format(po.Date, 'yyyyMM01')) as MonthCount
            ,cgh.CollectorGroupNum
            ,isnull(sum(pa.AmountPaid), 0) as TotalAmountPaid
            ,isnull(sum(pa.OtherPaid), 0) as TotalOtherPaid
            ,isnull(sum(pa.OtherPaid + case when cgh.CollectorGroupNum != '3' then pa.AmountPaid else 0 end), 0) as TotalPaid
    --        ,isnull(sum(pa.OtherPaid + case when cgh.CollectorGroupNum != 'B' then pa.AmountPaid else 0 end) / nullif(@PaymentDaysCount, 0) * @TotalDaysCount, 0) as ForecastPaid
            ,ceiling(count(distinct pa.ClientId) * 1.0 / count(distinct po.Date)) as AvgClientPay
            ,row_number()
                over (partition by cgh.CollectorGroupNum order by count(distinct pa.ClientId) * 1.0 / count(distinct po.Date)) * 1.0
                    / sum(count(distinct 1)) over (partition by cgh.CollectorGroupNum) as AvgClientPayProc
            ,isnull(sum(pa.OtherPaid + pa.AmountPaid) /  count(distinct pa.ClientId), 0) as AvgClientPaymentSum
            ,row_number()
                over (partition by cgh.CollectorGroupNum order by sum(pa.AmountPaid) /  count(distinct pa.ClientId)) * 1.0
                    / sum(count(distinct 1)) over (partition by cgh.CollectorGroupNum) as AvgClientPaymentSumProc
            ,count(distinct pa.ClientId) as TotalClientsPaid
                ,row_number()
                    over (partition by cgh.CollectorGroupNum order by count(distinct pa.ClientId)) * 1.0
                    / sum(count(distinct 1)) over (partition by cgh.CollectorGroupNum) as TotalClientsPaidProc
            ,sum(count(distinct 1)) over (partition by cgh.CollectorGroupNum) as CollectorsInGroup
        from #Portfolio po
        inner join #cgh cgh on cgh.CollectorId = po.CollectorId
            and cgh.Date = po.Date
        left join #Payments pa on po.CollectorId = pa.CollectorId
            and pa.Date = po.Date
        left join #Indicators tp on tp.CollectorGroupNum = cgh.CollectorGroupNum
            and tp.Indicator = 'TotalPaid'
        group by
            po.CollectorId
            ,cgh.CollectorGroupNum
            ,tp.ValueFrom
    )

    ,AvgPortfolio as
    (
        select distinct
            po.CollectorId
            ,cgh.CollectorName
            ,cgh.CollectorGroupNum
            ,cgh.CollectorGroupName
            ,sum(avg(po.Portfolio)) over (partition by po.CollectorId, cgh.CollectorGroupNum) as AvgPortfolio
            ,isnull(
                max(max(case when cgh.PrevCollectorGroup is null or cgh.PrevCollectorGroup != cgh.CollectorGroupNum then po.Date end))
                    over (partition by po.CollectorId, cgh.CollectorGroupNum)
                ,min(min(po.Date)) over (partition by po.CollectorId, cgh.CollectorGroupNum)
            ) as GroupStart
            ,case
                when max(max(po.Date)) over (partition by po.CollectorId, cgh.CollectorGroupNum) = @dateTo
                then 'Current' -- sum(pa.OtherPaid + case when cgh.CollectorGroupNum != 'B' then pa.AmountPaid else 0 end)
                else 'Old'
            end as CollectorToGroupAssign
            ,max(max(po.Date)) over (partition by po.CollectorId, cgh.CollectorGroupNum) as md
        from #Portfolio po
        inner join #cgh cgh on cgh.CollectorId = po.CollectorId
            and cgh.Date = po.Date
        group by
            po.CollectorId
            ,cgh.CollectorName
            ,cgh.CollectorGroupNum
            ,cgh.CollectorGroupName
            ,format(po.Date, 'yyyyMM01')
    )

    ,pd as 
    (
        select
            po.CollectorId
            ,count(*) as DaysHeCouldHaveBeenPaid
        from #Portfolio po
        inner join AvgPortfolio ap on po.CollectorId = ap.CollectorId
            and po.Date >= ap.GroupStart
            and po.Date <= @datePayTo
        where not exists
            (
                select 1 from AvgPortfolio ap2
                where ap2.CollectorId = ap.CollectorId
                    and ap2.GroupStart > ap.GroupStart
            )
        group by po.CollectorId
    )
    
    ,forecast as
    (
        select
            ap.CollectorId
            ,ap.CollectorGroupNum
            ,sum(p.OtherPaid + case when ap.CollectorGroupNum != '3' then p.AmountPaid else 0 end) as PaidLastPeriod
            ,sum(p.OtherPaid + case when ap.CollectorGroupNum != '3' then p.AmountPaid else 0 end) / pd.DaysHeCouldHaveBeenPaid as PaidPerDay
            ,sum(p.OtherPaid + case when ap.CollectorGroupNum != '3' then p.AmountPaid else 0 end) / pd.DaysHeCouldHaveBeenPaid * @daysLeftInPeriod as ForecastPayments
        from AvgPortfolio ap
        inner join pd on pd.CollectorId = ap.CollectorId
        left join #Payments p on p.CollectorId = ap.CollectorId
            and p.Date >= ap.GroupStart
        where not exists
            (
                select 1 from AvgPortfolio ap2
                where ap2.CollectorId = ap.CollectorId
                    and ap2.GroupStart > ap.GroupStart
            )
        group by
            ap.CollectorId
            ,ap.CollectorGroupNum
            ,ap.GroupStart
            ,pd.DaysHeCouldHaveBeenPaid
    )
    
    ,pre as 
    (
        select
            apo.CollectorId
            ,apo.CollectorGroupNum as CollectorGroup
            ,apo.CollectorGroupName
            ,apo.CollectorToGroupAssign
            ,apo.CollectorName
            ,p.CollectorHadPortfolioDays
            ,p.PeriodPlanned
            ,p.TotalAmountPaid
            ,p.TotalOtherPaid
            ,p.TotalPaid
            ,p.TotalPaid + isnull(f.ForecastPayments, 0) as ForecastPaid
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
            ,case when p.CollectorHadPortfolioDays < @RealDaysCount then '#ED6C49' end as CollectorColor
            ,isnull(p.TotalPaid / nullif(apo.AvgPortfolio, 0), 0) as Efficiency
            ,row_number() over (partition by apo.CollectorGroupNum order by isnull(p.TotalPaid / nullif(apo.AvgPortfolio, 0), 0)) * 1.0 / CollectorsInGroup as EfficiencyProc
            ,effM3.M3
            ,effM3.M2
            ,effM3.M1
        from AvgPortfolio apo
        left join #effM3 effM3 on effM3.CollectorId = apo.CollectorId
        left join forecast f on f.CollectorId = apo.CollectorId
            and f.CollectorGroupNum = apo.CollectorGroupNum
        left join pay p on p.CollectorId = apo.CollectorId
            and p.CollectorGroupNum = apo.CollectorGroupNum
        left join #Indicators pc on pc.Indicator = 'TotalPaidPercent'
            and (p.TotalPaid / p.PeriodPlanned >= pc.ValueFrom or pc.ValueFrom is null)
            and (p.TotalPaid / p.PeriodPlanned < pc.ValueTo or pc.ValueTo is null)
        left join #Indicators fc on fc.CollectorGroupNum = apo.CollectorGroupNum
            and fc.Indicator = 'ForecastPaid'
            and ((p.TotalPaid + isnull(f.ForecastPayments, 0)) >= fc.ValueFrom or fc.ValueFrom is null)
            and ((p.TotalPaid + isnull(f.ForecastPayments, 0)) < fc.ValueTo or fc.ValueTo is null)

        left join #Indicators ap on ap.CollectorGroupNum = apo.CollectorGroupNum
            and ap.Indicator = 'AveragePortfolio'
            and (apo.AvgPortfolio >= ap.ValueFrom * p.MonthCount or ap.ValueFrom is null)
            and (apo.AvgPortfolio < ap.ValueTo * p.MonthCount or ap.ValueTo is null)
        left join #Indicators cp on cp.Indicator = 'DefaultRange'
            and (p.AvgClientPayProc >= cp.ValueFrom or cp.ValueFrom is null)
            and (p.AvgClientPayProc < cp.ValueTo or cp.ValueTo is null)
            and apo.CollectorGroupNum in ('3', '4')
        left join #Indicators cps on cps.Indicator = 'DefaultRange'
            and (p.AvgClientPaymentSumProc >= cps.ValueFrom or cps.ValueFrom is null)
            and (p.AvgClientPaymentSumProc < cps.ValueTo or cps.ValueTo is null)
            and apo.CollectorGroupNum in ('3', '4')
        left join #Indicators tcp on tcp.Indicator = 'DefaultRange'
            and (p.TotalClientsPaidProc >= tcp.ValueFrom or tcp.ValueFrom is null)
            and (p.TotalClientsPaidProc < tcp.ValueTo or tcp.ValueTo is null)
            and apo.CollectorGroupNum in ('3', '4')
    )
    
    select
        p.*
        ,ef.color as EfficiencyColor
    from pre p
    left join #Indicators ef on ef.Indicator = 'DefaultRange'
        and (p.EfficiencyProc >= ef.ValueFrom or ef.ValueFrom is null)
        and (p.EfficiencyProc < ef.ValueTo or ef.ValueTo is null)

end
GO
