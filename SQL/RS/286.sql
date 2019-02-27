with u as 
(
    select 'v.zhivoglyadova' as username, 1 as ord union all
    select 's.zherebyatnikov' as username, 2 as ord union all
    select 't.samochernova' as username, 3 as ord union all
    select 'd.sviridova' as username, 4 as ord union all
    select 'o.strelchenko' as username, 5 as ord union all
    select 's.lange' as username, 6 as ord union all
    select 'd.sukhov' as username, 7 as ord union all
    select 'n.shevlukov' as username, 8 as ord union all
    select 'm.nazarov' as username, 9 as ord union all
    select 'a.vysotsky' as username, 10 as ord
)

select a.username, c.id as CollectorId, cg.GroupId, c.IsDisabled
-- 1) update c set IsDisabled = 1
-- 2) POST /api/Collector/RedistributionOverdueProducts ("fullRedistribution": false)
-- Следующий шаг нужен если коллектор уволен, а не ушел в отпуск или что-то такое
-- 3) delete cg
from sts.vw_admins a
inner join u on u.Username = a.username
inner join Collector.Collector c on c.UserId = a.id
left join Collector.CollectorGroup cg on cg.CollectorId = c.Id
order by u.ord