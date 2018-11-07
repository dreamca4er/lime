select distinct fu.EmailAddress
from dbo.FrontendUsers fu with (nolock)
inner join dbo.UserCards uc with (nolock) on uc.UserId = fu.id
    and uc.IsDied = 0
outer apply
(
    select top 1 ush.Status
    from dbo.UserStatusHistory ush with (nolock)
    where ush.UserId = fu.id
        and ush.IsLatest = 1
    order by ush.DateCreated desc
) ush
where ush.Status != 12
    and fu.EmailAddress is not null