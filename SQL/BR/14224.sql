drop table if exists #c
;

select
    c.clientid
    , c.LastName
    , c.FirstName
    , c.FatherName
    , c.PhoneNumber
    , c.Email
    , c.Passport
into #c
from client.vw_Client c
outer apply
(
    select top 1 
        p.DatePaid as LastDatePaid
        , iif(p.ProductType = 1, 23, 33) as DaysFromNow
    from prd.vw_product p
    where p.ClientId = c.ClientId
        and p.Status = 5
    order by p.DatePaid desc
) p
outer apply
(
    select avg(datediff(d, p.StartedOn, p.DatePaid) + 1) as AverageCreditLife
    from prd.vw_Product p
    where p.ClientId = c.ClientId
        and p.Status = 5
) acl
where not exists
    (
        select 1 from prd.vw_product p
        where p.ClientId = c.ClientId
            and p.Status not in (1, 5)
    )
    and p.LastDatePaid >= dateadd(d, -p.DaysFromNow, getdate())
    and c.Status = 2
    and c.IsFrauder = 0
    and c.IsDead = 0
    and c.IsCourtOrdered = 0
    and acl.AverageCreditLife > 5
    and not exists
    (
        select 1 from dbo.CustomListUsers clu
        where clu.ClientId = c.clientid
            and clu.DateCreated > dateadd(d, -180, getdate())
    )
;

select
    c.clientid
    , c.LastName
    , c.FirstName
    , c.FatherName
    , c.PhoneNumber
    , c.Email
from #c c
where 1=1
    and not exists
    (
        select 1 from "BOR-DB-LIME-2".Borneo.prd.vw_product p
        inner join "BOR-DB-LIME-2".Borneo.client."Identity" i on i.ClientId = p.ClientId
        where i.Number = c.Passport 
            and p.Status not in (1, 5) 
            
        union all
        
        select 1 from "BOR-DB-LIME-2".Borneo.client."Identity" i
        inner join "BOR-DB-LIME-2".Borneo.client.Client cl on cl.id = i.ClientId
        where i.Number = c.Passport
            and 1 in (cl.IsFrauder, cl.IsDead, cl.IsCourtOrdered)
    )
    and not exists
    (
        select 1 from "BOR-MANGO-DB".Borneo.prd.vw_product p
        inner join "BOR-MANGO-DB".Borneo.client."Identity" i on i.ClientId = p.ClientId
        where i.Number = c.Passport 
            and p.Status not in (1, 5) 
            
        union all
        
        select 1 from "BOR-MANGO-DB".Borneo.client."Identity" i
        inner join "BOR-MANGO-DB".Borneo.client.Client cl on cl.id = i.ClientId
        where i.Number = c.Passport
            and 1 in (cl.IsFrauder, cl.IsDead, cl.IsCourtOrdered)
    )