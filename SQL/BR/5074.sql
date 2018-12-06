with c as 
(
    select
        c.clientid
        ,c.FirstName
        ,c.LastName
        ,c.FatherName
        ,c.PhoneNumber
        ,c.Email
    from client.vw_Client c
    where exists 
            (
                select 1 
                from prd.vw_product p
                where p.ClientId = c.clientid
                    and p.ProductType = 1
                    and p.Status = 5
            )
        and not exists
            (
                select 1
                from prd.vw_product p
                where p.ClientId = c.clientid
                    and p.Status in (2, 3, 4, 7)
            )
        and not exists
            (
                select 1
                from prd.vw_product p
                where p.ClientId = c.clientid
                    and p.ProductType = 2
                    and p.Status >= 2
            )
        and not exists 
            (
                select 1 from client.UserProductBlock upb
                where upb.ClientId = c.clientid
                    and upb.ProductType = 2
                    and upb.BlockingPeriod > 0
            )
        and c.IsFrauder = 0
        and c.IsDead = 0
        and c.Status = 2
        and c.IsCourtOrdered = 0
        and c.DebtorProhibitInteractionType = 0
)

,s as 
(
    select
        p.ClientId
        ,sl.Status
        ,sl.StartedOn as StatusStart
        ,lead(sl.StartedOn) over (partition by sl.ProductId order by sl.StartedOn) as StatusEnd
    from c
    inner join prd.Product p on p.ClientId = c.ClientId
    inner join prd.vw_statusLog sl on sl.ProductId = p.id
)

select
    c.*
    ,th.TariffName
    ,th.MaxAmount
    ,crr.Score
    ,datediff(d, crr.CreatedOn, getdate()) as ScoreAge
from c
left join client.vw_TariffHistory th on th.ClientId = c.ClientId
    and th.IsLatest = 1
    and th.ProductType = 2
outer apply
(
    select top 1 
        crr.Score
        ,crr.CreatedOn
    from cr.CreditRobotResult crr
    where crr.ClientId = c.ClientId
    order by crr.CreatedOn desc
) crr
where not exists 
        (
            select 1
            from s
            where s.ClientId = c.ClientId
                and s.Status = 4 
                and datediff(d, StatusStart, StatusEnd) + 1 > 8
        )