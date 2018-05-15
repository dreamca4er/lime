select
    t.id as ClientId
    ,c.creditid
    ,c.DatePaid
    ,case when c.DatePaid is null and c.Prolong >= '20180419' then c.Prolong end
    ,case when c.DatePaid is null and c.Prolong >= '20180319' and c.Prolong < '20180419' then c.Prolong end 
from #tmp t
outer apply
(
    select top 1
        c.id as creditid
        ,c.DateStarted as CreditStart
        ,c.DatePaid
        ,csh.DateStarted as Prolong
        ,c.Status
    from dbo.Credits c
    outer apply
    (
        select top 1 csh.Status, csh.DateStarted
        from dbo.CreditStatusHistory csh
        where csh.Status in (1, 6)
            and csh.CreditId = c.id
        order by csh.DateStarted desc, id desc
    ) csh
    where c.UserId = t.id
        and c.DateStarted < '20180419'
        --and (c.DatePaid is null or c.DatePaid >= '20180419')
    order by c.DateStarted desc
) c
