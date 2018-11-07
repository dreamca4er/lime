select
    cast(format(p.StartedOn, 'yyyyMM01') as date) as Mnth
    ,case isnull(op.cnt, 0) + isnull(np.cnt, 0)
        when 0 then 'New'
        else 'Old'
    end as ClientType
    ,count(*) as ProductCount
    ,sum(Amount) as ProductSum
    ,'Lime' as Project
from prd.vw_product p
outer apply
(
    select count(*) as cnt
    from bi.OldProducts op
    where op.ClientId = p.ClientId
        and op.ProductId < p.Productid
) op
outer apply
(
    select count(*) as cnt
    from prd.vw_product p2
    where p2.ClientId = p.ClientId
        and p2.Status > 2
        and p2.Productid < p.Productid
) np
where p.Status > 2
    and p.StartedOn >= '20180101'
group by cast(format(p.StartedOn, 'yyyyMM01') as date)
    ,case isnull(op.cnt, 0) + isnull(np.cnt, 0)
            when 0 then 'New'
            else 'Old'
        end

/

select
    cast(format(c.DateStarted, 'yyyyMM01') as date) as Mnth
    ,case cast(right(c.DogovorNumber, 3) as int)
        when 1 then 'New'
        else 'Old'
    end as ClientType
    ,count(*) as ProductCount
    ,sum(Amount) as ProductSum
    ,'Konga' as Project
from dbo.Credits c
where c.Status not in (5, 8)
    and c.DateStarted >= '20180101'
group by 
    cast(format(c.DateStarted, 'yyyyMM01') as date)
    ,case cast(right(c.DogovorNumber, 3) as int)
        when 1 then 'New'
        else 'Old'
    end