select
    p.TariffName
    ,count(*) as Total
    ,count(sl.OverdueStart) as WithOverdue
    ,count(*) - count(sl.OverdueStart) as WithoutOverdue
from prd.vw_Product p
outer apply
(
    select top 1 StartedOn as OverdueStart
    from prd.vw_statusLog sl
    where sl.ProductId = p.Productid
        and sl.Status = 4
) sl
where p.Status = 5
    and p.DatePaid >= '20180101'
    and p.ProductType = 1
group by p.TariffName
order by 
    case 
        when p.TariffName like 'Start%[123]'
        then 1
        when p.TariffName like 'Start%'
        then 2
        when p.TariffName like 'Silver%[123]'
        then 3
        when p.TariffName like 'Silver%'
        then 4
        when p.TariffName like 'Gold%[123]'
        then 5
        when p.TariffName like 'Gold%'
        then 6
        else 7
    end
    ,reverse(p.TariffName)


select
    ts.TariffName
    ,count(*) as Total
    ,count(sl.Overdue) as WithOverdue
    ,count(*) - count(sl.Overdue) as WithoutOverdue
from dbo.Credits c
cross apply
(
    select top 1
        ts.StepName as TariffName
        ,ts.StepOrder
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    where uth.UserId = c.UserId
        and uth.DateCreated <= c.DateCreated
        and ts.TariffID = c.TariffId
    order by uth.DateCreated desc
) ts
outer apply
(
    select top 1 csh.DateCreated as Overdue
    from dbo.CreditStatusHistory csh
    where csh.CreditId = c.id
        and csh.Status = 3
) sl
where datepart(year, c.DatePaid) = 2018
    and c.TariffId = 2
group by ts.TariffName, ts.StepOrder
order by ts.StepOrder
 