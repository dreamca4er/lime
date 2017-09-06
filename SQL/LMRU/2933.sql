select 
    case 
        when Way = -1 then 'Contact'
        when Way = -2 then N'На банковский счет'
        when Way = -3 then N'На банковскую карту'
    end as "Способ"
    ,count(*) as "Кол-во"
    ,count(case when c.Amount >= 50000 then 1 end) as "Больше 50 т.р."
    ,count(case when c.Amount < 50000 then 1 end) as "Меньше 50 т.р."
    ,avg(c.Amount) as "Средний чек"
    ,min(c.Amount) as "Минимальный займ"
    ,max(c.Amount) as "Максимальный займ"
from dbo.Credits c
where TariffId = 4
    and status != 8
group by way