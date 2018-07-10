select
    p.StartedOn
    ,p.StatusName
    ,c.clientid
    ,c.fio
    ,c.BirthDate
    ,i.Number
    ,bu.*
from prd.vw_product p
inner join client.vw_client c on c.clientid = p.ClientId
inner join client."Identity" i on i.ClientId = c.clientid
cross apply
(
    select * 
    from cr.BlackListUser bu
    where bu.Firstname = c.FirstName
        and bu.Lastname = c.LastName
        and isnull(bu.Fathername, '') = isnull(c.FatherName, '')
        and bu.Birthday = c.BirthDate
--                and i.Number in (select value from openjson('["' + replace(replace(bu.Passports, ',', '","'), ' ', '') + '"]'))
) bu
where p.Status in (3, 4, 7)
    and not exists 
        (
            select 1 from prd.vw_product p1
            where p1.ClientId = p.ClientId
                and p1.Status = 5
                and p1.Productid < p.Productid
        )
    and not exists 
        (
            select 1 from bi.OldProducts op
            where op.ClientId = p.ClientId
                and op.Status = 2 
                and op.Productid < p.Productid
        )
