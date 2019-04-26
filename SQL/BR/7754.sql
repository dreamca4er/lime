select
    dateadd(month, datediff(month, 0, c.DateStarted), 0) as "Месяц"
    , count(*) as "Новых клиентов"
    , count(nc.HadNextCredit) as "Из них взяли займ повторно"
from dbo.Credits c
outer apply
(
    select top 1 1 as HadNextCredit
    from dbo.Credits c2
    where c2.UserId = c.UserId
        and c2.Status not in (5, 8)
        and c2.Id != c.Id
) nc
where c.DateStarted >= '20181001'
    and c.DateStarted < '20190201'
    and right(c.DogovorNumber, 3) = '001'
    and c.Status not in (5, 8)
group by dateadd(month, datediff(month, 0, c.DateStarted), 0)