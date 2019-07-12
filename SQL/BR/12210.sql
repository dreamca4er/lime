select
    case project_id
        when 0 then N'Лайм'
        when 1 then N'Конга'
        when 2 then N'Манго'
    end as Project
    , b.client_id
    , cc.fio
    , cc.substatusName as ClientStatus
    , ush.CreatedOn as StatusDate
    , isnull(p.StatusName, N'Не было кредитов') as ProductStatus
    , crr.LastScore
    , m.*
    , k.*
    , l.*
from Borneo.dbo.br12210 b
inner join client.vw_Client cc on cc.clientid = b.client_id
outer apply
(
    select top 1 coalesce(crr.Score, crr.ShortTermScore, crr.LongTermScore) as LastScore
    from cr.CreditRobotResult crr
    where crr.ClientId = cc.clientid
    order by crr.CreatedOn desc 
) crr
outer apply
(
    select top 1 p.StatusName
    from prd.vw_product p
    where p.ClientId = b.client_id
        and p.Status >= 2
    order by p.CreatedOn desc
) p
outer apply
(
--    select count(*) as MangoCount
    select
        c.ClientId as MangoClientId
        , c.Fio as MangoFio
        , isnull(p.StatusName, N'Не было кредитов') as MangoProductStatus
        , c.SubStatusName as MangoClientStatus
        , ush.CreatedOn as MangoStatusDate
    from "MAIN-DB-NODE".Borneo.Client.vw_Client c
    outer apply
    (
        select top 1 p.StatusName
        from "MAIN-DB-NODE".Borneo.prd.vw_product p
        where p.ClientId = c.clientid
            and p.Status >= 2
        order by p.CreatedOn desc
    ) p
    outer apply
    (
        select top 1 coalesce(crr.Score, crr.ShortTermScore, crr.LongTermScore) as LastScore
        from "MAIN-DB-NODE".Borneo.cr.CreditRobotResult crr
        where crr.ClientId = c.clientid
        order by crr.CreatedOn desc 
    ) crr
    left join "MAIN-DB-NODE".Borneo.client.UserStatusHistory ush on ush.ClientId = c.clientid
        and ush.IsLatest = 1
    where c.Passport = cc.Passport
        and b.project_id != 2
        and c.SubStatus >= 200
        and (crr.LastScore > 0 or p.StatusName is not null)
) m
outer apply
(

--    select count(*) as KongaCount
    select
        c.ClientId as KongaClientId
        , c.Fio as KongaFio
        , isnull(p.StatusName, N'Не было кредитов') as KongaProductStatus
        , c.SubStatusName as KongaClientStatus
        , ush.CreatedOn as KongaStatusDate
    from "BOR-KONGA-DB".Borneo.Client.vw_Client c
    outer apply
    (
        select top 1 p.StatusName
        from "BOR-KONGA-DB".Borneo.prd.vw_product p
        where p.ClientId = c.clientid
            and p.Status >= 2
        order by p.CreatedOn desc
    ) p
    outer apply
    (
        select top 1 coalesce(crr.Score, crr.ShortTermScore, crr.LongTermScore) as LastScore
        from "BOR-KONGA-DB".Borneo.cr.CreditRobotResult crr
        where crr.ClientId = c.clientid
        order by crr.CreatedOn desc 
    ) crr
    left join "BOR-KONGA-DB".Borneo.client.UserStatusHistory ush on ush.ClientId = c.clientid
        and ush.IsLatest = 1
    where c.Passport = cc.Passport
        and b.project_id != 1
        and c.SubStatus >= 200
        and (crr.LastScore > 0 or p.StatusName is not null)
) k
outer apply
(
--    select count(*) as LimeCount
    select
        c.ClientId as LimeClientId
        , c.Fio as LimeFio
        , isnull(p.StatusName, N'Не было кредитов') as LimeProductStatus
        , c.SubStatusName as LimeClientStatus
        , ush.CreatedOn as LimeStatusDate
    from "BOR-LIME-DB".Borneo.Client.vw_Client c
    outer apply
    (
        select top 1 p.StatusName
        from "BOR-LIME-DB".Borneo.prd.vw_product p
        where p.ClientId = c.clientid
            and p.Status >= 2
        order by p.CreatedOn desc
    ) p
    outer apply
    (
        select top 1 coalesce(crr.Score, crr.ShortTermScore, crr.LongTermScore) as LastScore
        from "BOR-LIME-DB".Borneo.cr.CreditRobotResult crr
        where crr.ClientId = c.clientid
        order by crr.CreatedOn desc 
    ) crr
    left join "BOR-LIME-DB".Borneo.client.UserStatusHistory ush on ush.ClientId = c.clientid
        and ush.IsLatest = 1
    where c.Passport = cc.Passport
        and b.project_id != 0
        and c.SubStatus >= 200
        and (crr.LastScore > 0 or p.StatusName is not null)
) l
left join client.UserStatusHistory ush on ush.ClientId = b.client_id
        and ush.IsLatest = 1
where project_id = (select ProjectID from bi.ProjectConfig)

