select 
    cr.ClientId
    ,cr.CreatedOn
    ,cr.Score
    ,cr.Reason
    ,cc.CredCnt
    ,st.CreatedOn
    ,st.TariffName
    ,lt.CreatedOn
    ,lt.TariffName
from cr.CreditRobotResult cr
inner join client.vw_client c on c.clientid = cr.ClientId
outer apply
(
    select count(*) as CredCnt
    from prd.vw_product p
    where p.ClientId = cr.ClientId
        and p.Status = 5
        and p.DatePaid < cr.CreatedOn
) cc
outer apply
(
    select top 1 
        st.CreatedOn
        ,st.CreatedBy
        ,st.TariffName
    from client.vw_TariffHistory st
    where st.ClientId = cr.ClientId
        and st.ProductType = 1
        and st.CreatedOn > cr.CreatedOn
        and not exists 
            (
                select 1 from cr.CreditRobotResult cr2
                where cr2.ClientId = st.ClientId
                    and cr2.CreatedOn < st.CreatedOn
                    and cr2.CreatedOn > cr.CreatedOn
            )
    order by st.CreatedOn
) st
outer apply
(
    select top 1 
        lt.CreatedOn
        ,lt.CreatedBy
        ,lt.TariffName
    from client.vw_TariffHistory lt
    where lt.ClientId = cr.ClientId
        and lt.ProductType = 2
        and lt.CreatedOn > cr.CreatedOn
        and not exists 
            (
                select 1 from cr.CreditRobotResult cr2
                where cr2.ClientId = lt.ClientId
                    and cr2.CreatedOn < lt.CreatedOn
                    and cr2.CreatedOn > cr.CreatedOn
            )
    order by lt.CreatedOn
) lt
where cr.Score > 0.85
    and cr.CreatedOn >= '20180913'
    and not exists 
        (
            select 1 from prd.vw_product p2
            where p2.ClientId = cr.ClientId
                and p2.Status > 2
                and p2.CreatedOn < cr.CreatedOn
                and (p2.DatePaid is null or p2.DatePaid > cr.CreatedOn)
        )
    and st.CreatedBy = c.userid
    and lt.CreatedBy = c.userid
    and cast(st.CreatedOn as date) = cast(lt.CreatedOn as date)