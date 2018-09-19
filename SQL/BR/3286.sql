declare @root varchar(100) = 'xmlns="http://schemas.datacontract.org/2004/07/Fuse8.Websites.LimeZaim.Domain"';
;
    
drop table if exists #NP
;

drop table if exists #OP
;

select
    p.Productid
    ,p.Period
    ,datediff(d, p.StartedOn, p.DatePaid) as ActualPeriod
    ,case 
        when sl.HadOverdue = 1 then null
        else datediff(d, p.StartedOn, p.DatePaid)
    end / 14.0 as ActualPeriod14
    ,sl.HadOverdue
    ,p.TariffName
    ,Amount
into #NP
from prd.vw_product p
outer apply
(
    select count(distinct 1) as HadOverdue 
    from prd.vw_statusLog sl
    where sl.ProductId = p.Productid
        and sl.Status = 4
) sl
where p.ProductType = 2
    and p.Status = 5
;

select
    c.id as ProductId
    ,c.Period
    ,datediff(d, c.DateStarted, c.DatePaid) as ActualPeriod
    ,case 
        when csh.HadOverdue = 1 then null
        else datediff(d, c.DateStarted, c.DatePaid)
    end / 14.0 as ActualPeriod14
    ,csh.HadOverdue
    ,cast(replace(c.ConditionSnapshot, @root, '') as xml).value('(TariffStep[1]/Name[1])', 'nvarchar(20)') as TariffName
    ,Amount
into #OP
from "LIME-DB".LimeZaim_Website.dbo.Credits c with (nolock)
outer apply
(
    select count(distinct 1) as HadOverdue  
    from "LIME-DB".LimeZaim_Website.dbo.CreditStatusHistory csh with (nolock)
    where csh.CreditId = c.id
        and csh.Status = 3
) as csh
where TariffId = 4
    and not exists 
        (
            select 1 from #NP
            where #NP.Productid = c.id
        )
    and c.Status = 2
;
/
with per as 
(
    select
        datediff(d, '19000101', dt1) as PeriodFrom
         ,datediff(d, '19000101', dt1) + 1 as PeriodTo
    from bi.tf_gendate('19000101', dateadd(d, 11, '19000101'))
)


,AP as 
(
    select * from #NP
    
    union all
    
    select * from #OP
)

select
    PeriodTo * 2 as WeeksCount
    ,ProductId
    ,Period
    ,ActualPeriod
    ,replace(TariffName, 'LimeUp\LimeUp', 'LimeUp') as TariffName
    ,Amount
from per
inner join AP prod on (prod.ActualPeriod14 > per.PeriodFrom or per.PeriodFrom = 0) 
    and prod.ActualPeriod14 <= per.PeriodTo

union

select
    9999 as WeeksCount
    ,Productid
    ,Period
    ,ActualPeriod
    ,replace(TariffName, 'LimeUp\LimeUp', 'LimeUp') as TariffName
    ,Amount
from AP prod
where HadOverdue = 1