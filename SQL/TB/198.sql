drop table if exists #cr
;

select
    row_number() over (order by DateCreated) as id
    ,u.UserId
    ,u.Passport
    ,u.fio
    ,u.proj
    ,c.DateCreated
    ,row_number() over (partition by u.Passport order by DateCreated) as rn
into #cr
from dbo.tb198Cronos c
inner join dbo.Tb198User u on u.UserId = c.UserId
where u.Passport is not null
;

drop table if exists #crd
;

with cte (id, Passport, AnchorDate, IsUnique, rn) as 
(
    select
        id
        ,Passport
        ,DateCreated as AnchorDate
        ,1 as IsUnique
        ,cr.rn
    from #cr cr
    where rn = 1
    
    union all
    
    select
        cr.id
        ,cr.Passport
        ,case when datediff(d, cte.AnchorDate, cr.DateCreated) >= 200 then cr.DateCreated else cte.AnchorDate end 
        ,case when datediff(d, cte.AnchorDate, cr.DateCreated) >= 200 then 1 else 0 end
        ,cr.rn
    from cte
    inner join #cr cr on cr.Passport = cte.Passport
        and cr.rn = cte.rn + 1
)

select *
into #crd
from cte
;

select
    cr.userid
    ,cr.Passport
    ,cr.fio
    ,cr.proj
    ,cr.DateCreated
    ,crd.IsUnique
from #crd crd
inner join #cr cr on cr.id = crd.id
where crd.passport = '4614804326'

drop table if exists #eq
;

select
    row_number() over (order by DateCreated) as id
    ,u.UserId
    ,u.Passport
    ,u.fio
    ,u.proj
    ,c.DateCreated
    ,row_number() over (partition by u.Passport order by DateCreated) as rn
into #eq
from dbo.tb198eq c
inner join dbo.Tb198User u on u.UserId = c.UserId
where u.Passport is not null
;

drop table if exists #eqd
;

with cte (id, Passport, AnchorDate, IsUnique, rn) as 
(
    select
        id
        ,Passport
        ,DateCreated as AnchorDate
        ,1 as IsUnique
        ,eq.rn
    from #eq eq
    where rn = 1
    
    union all
    
    select
        eq.id
        ,eq.Passport
        ,case when datediff(d, cte.AnchorDate, eq.DateCreated) >= 14 then eq.DateCreated else cte.AnchorDate end 
        ,case when datediff(d, cte.AnchorDate, eq.DateCreated) >= 14 then 1 else 0 end
        ,eq.rn
    from cte
    inner join #eq eq on eq.Passport = cte.Passport
        and eq.rn = cte.rn + 1
)

select *
into #eqd
from cte
option ( maxrecursion 365 )
;
