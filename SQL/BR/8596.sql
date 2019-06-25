select 
    count(*) as "Всего"
    , count(case when stt.id is not null and ltt.id is null then 1 end) as "Только тариф КЗ"
    , count(case when stt.id is null and ltt.id is not null then 1 end) as "Только тариф ДЗ"
    , count(case when stt.id is not null and ltt.id is not null then 1 end) as "Тариф КЗ и тариф ДЗ"
from client.client c
left join client.UserShortTermTariff stt on stt.ClientId = c.id
    and stt.IsLatest = 1
left join client.UserLongTermTariff ltt on ltt.ClientId = c.id
    and ltt.IsLatest = 1
where c.status = 2
    and exists
    (
        select 1 from client.vw_TariffHistory th
        where th.ClientId = c.id
            and th.IsLatest = 1
    )
    and not exists
    (
        select 1 from prd.vw_product p
        where p.ClientId = c.id
            and p.Status not in (1, 5)
    )