select
    c.id as CreditId
    , c.UserId
    , fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    , fu.mobilephone
    , t.*
from dbo.Credits c
inner join dbo.FrontendUsers fu on fu.id = c.UserId
outer apply
(
    select top 1
        max(isnull(tsst.StepMaxAmount, tslt.StepMaxAmount)) as ma
    from dbo.UserTariffHistory uth
    left join dbo.vw_TariffSteps tsst on tsst.StepID = uth.StepId
        and tsst.TariffID = 2
    left join dbo.vw_TariffSteps tslt on tslt.StepID = uth.StepId
        and tslt.TariffID = 4
    where uth.UserId = c.UserId
        and cast(dateadd(d, isnull(tsst.ActivePeriod, tslt.ActivePeriod), uth.DateCreated) as date) >= cast(getdate() as date)
) t
where c.Status = 5
    and c.Way = -2