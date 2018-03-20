select
    c.id as clientid
    ,concat(c.LastName, ' ', c.FirstName, ' ', c.FatherName) as fio
    ,c.DateRegistered
    ,apf.Description as AdminProcessingFlag
    ,vc.substatusName as ClientStatus
    ,vp.statusName as ProductStatus
    ,c.INN
    ,ul.*
    ,case 
        when c.DesiredProductType = 1 then N'КЗ'
        when c.DesiredProductType = 2 then N'ДЗ'
    end as DesiredProductType
    ,json_value(json_query(uai.AdditionalInfo, '$.DesiredConditionsTariff'), '$.Amount') as DesiredAmount
    ,json_value(json_query(uai.AdditionalInfo, '$.DesiredConditionsTariff'), '$.Period') as DesiredPeriod
    ,replace(replace(replace(th.Tariffs, '{"TariffName":', ''), '}', ''), '\\', '\') as Tariffs
from client.client c
inner join client.vw_client vc on vc.clientid = c.id
left join client.EnumAdminProcessingFlag apf on apf.Id = c.AdminProcessingFlag
left join client.UserAdditionalInfo uai on uai.ClientId = c.id
outer apply
(
    select top 1 
        ul.UtmName
        ,ul.UtmWmId
        ,ul.UtmPixelDateTime
    from client.UserLead ul
    where ul.ClientId = c.id
    order by ul.CreatedOn desc
) ul
outer apply
(
    select
        th.TariffName
    from client.vw_TariffHistory th 
    where th.IsLatest = 1
        and th.ClientId = c.id
    for json auto, without_array_wrapper
) th(Tariffs)
outer apply
(
    select top 1 vp.statusName
    from prd.vw_product vp
    where vp.clientId = c.id
    order by vp.productid desc
) vp
where c.INN in
    (
        select INN
        from client.client
        where INN != ''
        group by inn
        having count(*) > 1
    )
order by c.INN
/

select
    c.id as clientid
    ,concat(c.LastName, ' ', c.FirstName, ' ', c.FatherName) as fio
    ,c.DateRegistered
    ,apf.Description as AdminProcessingFlag
    ,vc.substatusName as ClientStatus
    ,vp.statusName as ProductStatus
    ,c.snils
    ,ul.*
    ,case 
        when c.DesiredProductType = 1 then N'КЗ'
        when c.DesiredProductType = 2 then N'ДЗ'
    end as DesiredProductType
    ,json_value(json_query(uai.AdditionalInfo, '$.DesiredConditionsTariff'), '$.Amount') as DesiredAmount
    ,json_value(json_query(uai.AdditionalInfo, '$.DesiredConditionsTariff'), '$.Period') as DesiredPeriod
    ,replace(replace(replace(th.Tariffs, '{"TariffName":', ''), '}', ''), '\\', '\') as Tariffs
from client.client c
inner join client.vw_client vc on vc.clientid = c.id
left join client.EnumAdminProcessingFlag apf on apf.Id = c.AdminProcessingFlag
left join client.UserAdditionalInfo uai on uai.ClientId = c.id
outer apply
(
    select top 1 
        ul.UtmName
        ,ul.UtmWmId
        ,ul.UtmPixelDateTime
    from client.UserLead ul
    where ul.ClientId = c.id
    order by ul.CreatedOn desc
) ul
outer apply
(
    select
        th.TariffName
    from client.vw_TariffHistory th 
    where th.IsLatest = 1
        and th.ClientId = c.id
    for json auto, without_array_wrapper
) th(Tariffs)
outer apply
(
    select top 1 vp.statusName
    from prd.vw_product vp
    where vp.clientId = c.id
    order by vp.productid desc
) vp
where c.snils in
    (
        select SNILS
        from client.Client
        where SNILS != ''
        group by SNILS
        having count(*) > 1
    )
order by c.snils
