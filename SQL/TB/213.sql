select distinct 
    c.userid
    ,floor(datediff(d, uc.Birthday, getdate()) / 365.0) as age
    ,case when uc.Gender = 1 then N'М' else N'Ж' end as gender
from dbo.credits c
inner join dbo.UserCards uc on uc.UserId = c.UserId
where c.Status not in (5,8)
    and cast(c.DateStarted as date) between '20170101' and '20171201'