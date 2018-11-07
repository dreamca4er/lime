
declare 
    @dateFrom date = '20180801'
    ,@dateTo date = getdate()

set @dateFrom = (select max(d) from (values (@dateFrom), ('20180901')) v(d))
;

drop table if exists #c
;

drop table if exists #cs
;

select distinct
    cd.ProductId
    ,p.CreatedOn
    ,cd.ClientId
into #c
from bi.CollectorPortfolioDetail cd
inner join prd.Product p on p.id = cd.ProductId
where cd.Date between @dateFrom and @dateTo
;

select *
into #cs
from #c cd
outer apply
(
    select top 1 
        nullif(crr.Score, 0) as Score  
    from cr.CreditRobotResult crr
    where crr.ClientId = cd.ClientId
        and crr.CreatedOn < cd.CreatedOn
    order by crr.CreatedOn desc
) crr
;

create index IX_cs_ProductId on #cs(ProductId)
;

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
where cd.Date between @dateFrom and @dateTo
    and cgh.CollectorGroup in ('B', 'C')
group by 
    cd.Date
    ,cd.CollectorId
    ,cgh.CollectorName
    ,cgh.CollectorGroupName