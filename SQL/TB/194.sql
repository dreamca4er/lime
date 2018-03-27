drop table if exists dbo.DeletedPhonesNumber
;

select
    pt.Description
    ,p.*
    ,row_number() over (partition by ClientId, PhoneNumber order by case when PhoneType = 8 then 1 else 2 end
                                                                    ,case when PhoneType = 5 then 1 else 2 end
                                                                    , case when PhoneType = 7 then 2 else 1 end) as rn
into dbo.DeletedPhonesNumber
from client.phone p
inner join client.EnumPhoneType pt on pt.Id = p.PhoneType
where exists 
    (
        select
            p1.ClientId
            ,p1.PhoneNumber
        from client.Phone p1
        where p1.PhoneNumber is not null
            and p1.IsDeleted = 0
            and p1.ClientId = p.ClientId
            and p1.PhoneNumber = p.PhoneNumber
            and p1.PhoneType != 1
        group by 
            p1.ClientId
            ,p1.PhoneNumber
        having count(*) > 1
    )
/

delete p
from dbo.DeletedPhonesNumber dp
inner join client.Phone p on p.Id = dp.id
    and dp.rn != 1
/

drop table #Phones
;

select
    pt.Description
    ,p.*
    ,row_number() over (partition by clientid, PhoneType order by PhoneNumber, UseForAutoCalling desc, Comment, CreatedOn desc) as rn
into #Phones
from client.phone p
inner join client.EnumPhoneType pt on pt.Id = p.PhoneType
where exists 
    (
        select
            p1.ClientId
            ,p1.PhoneType
        from client.Phone p1
        where p1.PhoneNumber is not null
            and p1.IsDeleted = 0
            and p1.ClientId = p.ClientId
            and p1.PhoneType = p.PhoneType
        group by 
            p1.ClientId
            ,p1.PhoneType
        having count(*) > 1
    )
order by ClientId, PhoneType

delete p1
from #Phones p
inner join client.Phone p1 on p1.id = p.id
    and p.rn != 1