    
    declare 
        @dateFrom date = '20180501'
        ,@dateTo date = '20180801'
    ;

    declare 
        @monthDiff int
    ;
    set language russian
    ;
    
    set @dateFrom = cast(format(@dateFrom, 'yyyyMM01') as date)
    ;
    
    set @dateTo = cast(format(@dateTo, 'yyyyMM01') as date)
    ;
    
    set @monthDiff = datediff(month, @dateFrom, @dateTo) + 1 
    ;
    
    set @dateFrom = (select max(d) from (values (dateadd(month, -1 * @monthDiff, @dateFrom)), ('20180301')) v(d))
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
        cast(format(cpd.Date, 'yyyyMM01') as date) as Mnth
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
        cast(format(cpd.Date, 'yyyyMM01') as date) as Mnth
        ,avg(pin.Score) as AverageScore
        ,count(case when pin.ClientType = 'NewClient' then 1 end) * 1.0 / count(*) as NewClientPart
        ,count(case when pin.ClientType = 'OldClient' then 1 end) * 1.0 / count(*) as OldClientPart
        ,count(case when pin.ProductType = 1 then 1 end) * 1.0 / count(*) as STPart
        ,count(case when pin.ProductType = 2 then 1 end) * 1.0 / count(*) as LTPart
        ,sum(cpd.AmountPaid) as AmountPaid
        ,sum(cpd.PercentPaid + cpd.Commissionpaid + cpd.FinePaid + cpd.ProlongPaid) as OtherPaid
    into #ClientsStats
    from bi.CollectorPortfolioDetail cpd
    inner join #prdInfo pin on pin.ProductId = cpd.ProductId
    where cpd.Date between @dateFrom and @dateTo
    group by cast(format(cpd.Date, 'yyyyMM01') as date)
    ;
    
    with d as 
    (
        select
            cast(format(cpd.Date, 'yyyyMM01') as date) as Mnth
            ,cpd.CollectorId
            ,cgh.CollectorGroup
            ,sum(cpd.ActiveAmountDebt + cpd.OverdueAmountDebt + cpd.ActivePercentDebt + cpd.OverduePercentDebt + cpd.FineDebt + cpd.CommissionDebt) as PortfolioSum
            ,count(*) as PortfolioCount
            ,sum(cpd.AmountPaid) as AmountPaid
            ,sum(cpd.PercentPaid + cpd.Commissionpaid + cpd.FinePaid + cpd.ProlongPaid) as OtherPaid
        from bi.CollectorPortfolioDetail cpd
        inner join bi.CollectorGroupHistory cgh on cgh.CollectorId = cpd.CollectorId
            and cgh.Date = cpd.Date
        where cpd.Date between @dateFrom and @dateTo
        group by cpd.Date, cpd.CollectorId, cgh.CollectorGroup
    )
    
    select
        d.Mnth
        ,avg(d.PortfolioSum) as AvgPortfolioSum
        ,avg(case when d.CollectorGroup = 'B' then d.PortfolioSum end) as AvgODVPortfolioSum
        ,avg(case when d.CollectorGroup = 'C' then d.PortfolioSum end) as AvgGTSPortfolioSum
        ,avg(d.PortfolioCount) as AvgPortfolioCount
        ,avg(case when d.CollectorGroup = 'B' then d.PortfolioCount end) as AvgODVPortfolioCount
        ,avg(case when d.CollectorGroup = 'C' then d.PortfolioCount end) as AvgGTSPortfolioCount
        ,count(distinct case when d.CollectorGroup in ('B', 'C') then CollectorId end) as UniqueEmployees
        ,count(distinct case when d.CollectorGroup = 'B' then d.CollectorId end) as UniqueODVEmployees
        ,count(distinct case when d.CollectorGroup = 'C' then d.CollectorId end) as UniqueGTSEmployees
    into #MoneyStats
    from d
    group by d.Mnth
    ;
    
    select
        cs.Mnth
        ,ms.AvgPortfolioSum
        ,ms.AvgODVPortfolioSum
        ,ms.AvgGTSPortfolioSum
        ,ms.AvgPortfolioCount
        ,ms.AvgODVPortfolioCount
        ,ms.AvgGTSPortfolioCount
        ,ms.UniqueEmployees
        ,ms.UniqueODVEmployees
        ,ms.UniqueGTSEmployees
        ,ts.UniqueTechCallers
        ,cs.AmountPaid + cs.OtherPaid as TotalPaid
        ,cs.AmountPaid
        ,cs.OtherPaid
        ,cs.AverageScore
        ,cs.STPart
        ,cs.LTPart
        ,cs.NewClientPart
        ,cs.OldClientPart
    from #ClientsStats cs
    inner join #MoneyStats ms on ms.Mnth = cs.Mnth
    left join #techCallers ts on ts.Mnth = cs.Mnth