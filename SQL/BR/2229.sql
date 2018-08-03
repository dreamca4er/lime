select
    cul.ClientId
    ,ustt.TariffName as STTariffName
    ,ultt.TariffName as LTTariffName
    ,p.Amount as STAmount
    ,p.StartedOn as STStartedOn
    ,p.StatusName as STStatus
    ,p2.Amount as LTAmount
    ,p2.StartedOn as LTStartedOn
    ,p2.StatusName as LTStatus
from dbo.CustomListUsers cul
left join client.vw_TariffHistory ustt on ustt.ClientId = cul.ClientId
    and ustt.IsLatest = 1
    and ustt.ProductType = 1
left join client.vw_TariffHistory ultt on ultt.ClientId = cul.ClientId
    and ultt.IsLatest = 1
    and ultt.ProductType = 2
left join prd.vw_product p on p.ClientId = cul.ClientId
    and p.ProductType = 1
    and p.Status in (3, 4, 7)
left join prd.vw_product p2 on p2.ClientId = cul.ClientId
    and p2.ProductType = 2
    and p2.Status in (3, 4, 7)
where CustomlistID = 1070

select
    ucl.UserId
    ,st.TariffName as STTariffName
    ,lt.TariffName as LTTariffName
    ,c.Amount
    ,c.DateStarted as STDateStarted
    ,case 
        when c.Status = 1 then N'Активен' 
        when c.Status = 3 then N'Просрочен' 
    end as STSTatus
    ,c2.Amount
    ,c2.DateStarted as LTDateStarted
    ,case 
        when c2.Status = 1 then N'Активен' 
        when c2.Status = 2 then N'Просрочен'
    end as LTSTatus
from dbo.UserCustomLists ucl
left join dbo.Credits c on c.UserId = ucl.UserId
    and c.Status in (1, 3)
    and c.TariffId != 4
left join dbo.Credits c2 on c2.UserId = ucl.UserId
    and c2.Status in (1, 3)
    and c2.TariffId = 4
outer apply
(
    select
        ts.TariffName + '/' + ts.StepName as TariffName
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
        and ts.TariffID != 4
    inner join dbo.Tariffs t on t.Id = ts.TariffID
    where uth.IsLatest = 1
--        and datediff(d, uth.DateCreated, getdate()) < t.ActivePeriod
        and uth.UserId = ucl.UserId
) st
outer apply
(
    select
        ts.TariffName + '/' + ts.StepName as TariffName
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
        and ts.TariffID = 4
    inner join dbo.Tariffs t on t.Id = ts.TariffID
    where uth.IsLatest = 1
--        and datediff(d, uth.DateCreated, getdate()) < t.ActivePeriod
        and uth.UserId = ucl.UserId
) lt
where ucl.CustomlistID = 44
