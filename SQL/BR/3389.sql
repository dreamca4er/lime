select
    cg.Name as GroupName
    ,avg(crr.Score) as AvgScore
from col.OverdueProduct op
inner join prd.Product p on p.id = op.ProductId
inner join col.CollectorGroup cg on cg.CollectorId = op.CollectorId
outer apply
(
    select top 1 
        nullif(crr.Score, 0) as Score
    from cr.CreditRobotResult crr
    where crr.ClientId = p.ClientId
        and crr.CreatedOn < p.CreatedOn
    order by crr.CreatedOn desc
) crr
where op.IsDeleted = 0
    and cg.Name in ('B', 'C')
group by cg.Name


/
select
    cast(CreatedOn as date)
    ,datediff(d, CreatedOn, getdate()) as DD
    ,count(case when isnull(Score, 0) = 0 then 1 end) as ZeroScore
    ,count(case when isnull(Score, 0) != 0 then 1 end) as OtherScore
from cr.CreditRobotResult
where CreatedOn > '20180501'
    and cast(CreatedOn as date) >= dateadd(d, 104, '20180518') 
group by cast(CreatedOn as date), datediff(d, CreatedOn, getdate())
/
drop table if exists #c
;

select
    min(cd.Date) as Date
    ,cd.ProductId
    ,cd.ClientId
into #c
from bi.CollectorPortfolioDetail cd
where cd.Date >= '20180830'
group by
    cd.ProductId
    ,cd.ClientId
;

select *
into #cs
from #c cd
outer apply
(
    select top 1 crr.Score 
    from cr.CreditRobotResult crr
    where crr.ClientId = cd.ClientId
        and crr.CreatedOn < cd.Date
    order by crr.CreatedOn desc
) crr
;

create index IX_cs_ProductId on #cs(ProductId)
;
/
select
    cd.Date
    ,cd.CollectorId
    ,cgh.CollectorName
    ,cgh.CollectorGroupName
    ,avg(cs.Score) as AvgScore
from bi.CollectorPortfolioDetail cd
inner join #cs cs on cs.ProductId = cd.ProductId
inner join bi.CollectorGroupHistory cgh on cgh.CollectorId = cd.CollectorId
    and cgh.Date = cd.Date
where cd.Date >= '20180830'
    and cgh.CollectorGroup in ('B', 'C')
group by 
    cd.Date
    ,cd.CollectorId
    ,cgh.CollectorName
    ,cgh.CollectorGroupName