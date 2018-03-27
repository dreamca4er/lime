with a as 
(
    select *
        , row_number() over (partition by p.ClientId, p.PhoneType, p.PhoneNumber order by UseForAutoCalling desc) as rn
    from client.Phone p
    where exists 
        (
            select
                p1.ClientId
                ,p1.PhoneNumber
                ,p1.PhoneType
            from client.Phone p1
            where p1.IsDeleted = 0
                and p1.ClientId = p.ClientId
                and p1.PhoneNumber = p.PhoneNumber
                and p1.PhoneType = p.PhoneType
                and p1.PhoneType != 1
            group by 
                p1.ClientId
                ,p1.PhoneNumber
                ,p1.PhoneType
            having count(*) > 1
        )
        and p.IsDeleted = 0
)

--select
--    p.*
--delete p 
--from a
inner join client.Phone p on p.id = a.id
where rn != 1

select * -- delete p
from client.Phone p
where p.IsMain != 1
    and exists 
            (
                select 1 from client.Phone p1
                where p1.ClientId = p.ClientId
                    and p1.PhoneNumber = p.PhoneNumber
                    and p1.IsMain = 1
            )