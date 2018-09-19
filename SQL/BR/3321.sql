drop table if exists #c
;
 
select
    c.clientid
    ,c.FirstName
    ,c.LastName
    ,c.FatherName
    ,c.PhoneNumber
    ,c.Email
    ,cs.Score
    ,isnull(op.STProductCount, 0) + isnull(np.STProductCount, 0) as STProductCount
    ,isnull(op.LTProductCount, 0) + isnull(np.LTProductCount, 0) as LTProductCount
    ,ustt.TariffName as STTariffName
    ,ultt.TariffName as LTTariffName
    ,case when act.ST > 0 then 1 end as ActST
    ,case when act.LT > 0 then 1 end as ActLT
    ,cast((select max(dt) from (values (np.LastSTPaid), (np.LastLTPaid)) d(dt)) as date) as LastCreditPaid 
    ,case 
        when np.LastSTPaid > np.LastLTPaid or np.LastSTPaid is not null and np.LastLTPaid is null
        then N'КЗ'
        when np.LastLTPaid > np.LastSTPaid or np.LastLTPaid is not null and np.LastSTPaid is null
        then N'ДЗ'
    end as LastCreditType
into #c
from client.vw_client c
left join client.vw_TariffHistory ustt on ustt.ClientId = c.clientid
    and ustt.IsLatest = 1
    and ustt.ProductType = 1
left join client.vw_TariffHistory ultt on ultt.ClientId = c.clientid
    and ultt.IsLatest = 1
    and ultt.ProductType = 2
outer apply
(
    select top 1 crr.Score 
    from cr.CreditRobotResult crr
    where crr.ClientId = c.clientid
    order by crr.CreatedOn desc
) cs
outer apply
(
    select
        count(case when th.ProductType = 1 then 1 end) as ST
        ,count(case when th.ProductType = 2 then 1 end) as LT
    from client.vw_TariffHistory th
    where th.ClientId = c.clientid
        and cast(th.CreatedOn as date) = '20180906'
) act
outer apply
(
    select
        count(case when op.TariffId != 4 then 1 end) as STProductCount
        ,count(case when op.TariffId = 4 then 1 end) as LTProductCount
    from bi.OldProducts op
    where op.clientid = c.clientid
        and not exists 
            (
                select 1 from prd.product p
                where op.ProductId = p.id
            )
    group by op.ClientId
) op
outer apply
(
    select
        count(case when p.ProductType = 1 then 1 end) as STProductCount
        ,count(case when p.ProductType = 2 then 1 end) as LTProductCount
        ,max(case when p.ProductType = 1 then DatePaid end) as LastSTPaid
        ,max(case when p.ProductType = 2 then DatePaid end) as LastLTPaid
    from prd.vw_product p
    where p.ClientId = c.clientid
        and p.Status = 5
) np
where (ustt.Id is not null or ultt.Id is not null)
    and not exists 
        (
            select 1 from prd.vw_product p
            where p.ClientId = c.clientid
                and p.Status in (2, 3, 4, 7)
        )
;

with eq as 
(
    select 
        ProjectClientId as clientid
        ,max(EquifaxRequestCreatedOn) as EquifaxRequestCreatedOn
    from cr.syn_EquifaxResponse er
    where er.ProjectClientId in (select clientid from #c)
    group by ProjectClientId
)

select
    c.*
    ,datediff(d, eq.EquifaxRequestCreatedOn, getdate()) as CHDays
from #c c
left join eq on eq.clientid = c.clientid
--where (eq.EquifaxRequestCreatedOn is null or datediff(d, eq.EquifaxRequestCreatedOn, getdate()) > 30)