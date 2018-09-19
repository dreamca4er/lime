with c as 
(
    select id as ClientId
    from client.Client
    where id in
    (
        2396313
        ,2035049
        ,2395126
        ,2394087
        ,2147426
        ,1381483
        ,1181136
        ,2389664
        ,2389433
        ,2389178
        ,2388155
        ,2148836
        ,2334198
        ,2241037
        ,2379326
        ,2384392
        ,2384309
        ,1730756
        ,2374551
        ,1594818
        ,2381182
        ,2115646
    )
)

,st as 
(
    select
        ClientId
        ,CreatedOn
        ,TariffName
    from client.vw_TariffHistory
    where CreatedOn >= '20180831'
        and ClientId in (select ClientId from c)
        and ProductType = 1
)

,lt as 
(
    select
        ClientId
        ,CreatedOn
        ,TariffName
    from client.vw_TariffHistory
    where CreatedOn >= '20180831'
        and ClientId in (select ClientId from c)
        and ProductType = 2
)

select
    isnull(st.ClientId, lt.ClientId) as ClientId
    ,st.CreatedOn as stCreatedOn
    ,st.TariffName as stTariffName
    ,lt.CreatedOn as ltCreatedOn
    ,lt.TariffName as ltTariffName
from st
full join lt on st.ClientId = lt.ClientId