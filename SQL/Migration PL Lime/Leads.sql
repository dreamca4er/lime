select
    isnull(c.CreditId, ui.UserId) as EntityId
    , ui.CompanyName
    , ui.UrlParameters
    , param.UrlXml.value('(/lead/@utm_medium)[1]', 'nvarchar(100)') as utm_medium
    , e.Label_en
    , ush.DateCreated
from dbo.UtmStepHistory ush
inner join dbo.UtmInfo ui on ui.Id = ush.UtmInfoId
left join dbo.Enums e on e.Val = ush.Step
    and e.Enum = 'PixelStep'
outer apply
(
    select top 1 
        c.id as CreditId
        , c.DateCreated as CreditCreatedOn 
    from dbo.Credits c
    where c.UserId = ui.UserId
        and c.Status <= 5
        and c.DateCreated < ush.DateCreated
        and ush.Step = 3
    order by c.DateCreated desc
) c
outer apply
(
    select 
    cast('<?xml version="1.0" encoding="utf-16"?><lead '
        + replace(replace(ui.UrlParameters
                , '=', '="')
                , '&', '" ')
        + '"/>' as xml) as UrlXml
) param
where ui.DateCreated >= '2018-07-12' --  Дата начала постбэков
    and ui.CompanyName = 'limelead'
    and Status = 1      -- Успех
    and ush.Type = 2    -- Постбэк
    and step in (3, 7)  -- Регистрация и выдача