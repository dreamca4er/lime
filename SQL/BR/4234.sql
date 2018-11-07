select SNILS, count(*)
from client.Client c
where cast(c.DateRegistered as date) >= dateadd(d, -30, '20181024')
    and cast(c.DateRegistered as date) < '20181024'
    and exists 
        (
            select 1 from client.Client c2
            where c2.SNILS = c.SNILS
                and cast(c2.DateRegistered as date) < dateadd(d, -30, '20181024')
        )
    and c.SNILS not like '000%'
group by SNILS