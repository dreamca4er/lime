/*
select top 100
    productid
    ,clientId
into #p1
from prd.vw_Product
where productType = 1
    and status = 3
order by productid desc
*/

--select top 100
--    productid
--    ,clientId
--into #p2
--from prd.vw_Product p
--where productType = 1
--    and status = 4
--    and not exists 
--                (
--                    select 1 from #p1 p1
--                    where p1.productid = p.productid
--                )
--order by productid desc

--select top 100
--    productid
--    ,clientId
--into #p6
--from prd.vw_Product
--where productType = 1
--    and status = 7
--order by productid desc

--select top 100
--    productid
--    ,clientId
--into #p4
--from prd.vw_Product p
--where productType = 1
--    and status = 5
--    and cast(p.datePaid as date) = cast(dateadd(d, Period, p.StartedOn) as date)
--order by productid desc

--select top 100
--    productid
--    ,clientId
--into #p5
--from prd.vw_Product p
--where productType = 1
--    and status = 5
--    and cast(p.datePaid as date) < cast(dateadd(d, Period, p.StartedOn) as date)
--order by productid desc

select clientid from #p1
union
select clientid from #p2
union
select *
from 
(
    select top 100
        clientid
    from prd.vw_product p
    cross apply
    (
        select top 1
            s.ScheduleSnapshot
            ,s.SchType
        from prd.LongTermScheduleLog sl
        inner join prd.LongTermSchedule s on s.Id = sl.ScheduleId
        where s.ProductId = p.productid
        order by sl.StartedOn desc
    ) s
    cross apply 
    (
        select avg(Total) as at
        from openjson(s.ScheduleSnapshot)
        with 
            (
                Total numeric(18,2)
            ) as t
    ) avgT
    cross apply
    (
        select top 1
            debtAmntOver + debtPercOver as debt
        from acc.pb(p.productid) pd
        where pd.productid = p.productid
        order by pd.date desc
    ) d
    where productType = 2
        and s.SchType = 1
        and p.status = 4
        and d.debt < -2 * avgT.at
    order by p.productid desc
) a

union
select clientid from #p4
union
select clientid from #p5
union
select clientid from #p6