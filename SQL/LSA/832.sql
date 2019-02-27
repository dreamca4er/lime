select 
    fu.id as ClientId
    , fu.LastName
    , fu.FirstName
    , fu.MobilePhone
    , fu.EmailAddress
    , reg.RegDate
    , e.Label as UserStatusKind
from dbo.Credits c
inner join dbo.FrontendUsers fu on fu.id = c.UserId
inner join dbo.UserStatusHistory ush on ush.UserId = fu.id
    and ush.IsLatest = 1
inner join dbo.Enums e on e.Val = ush.UserStatus
    and e.Enum = 'UserStatusKind'
outer apply
(
    select top 1 ush.DateCreated as RegDate
    from dbo.UserStatusHistory ush
    where ush.UserId = fu.id
        and ush.UserStatus = 1
    order by ush.DateCreated
) reg
where cast(c.DatePaid as date) between '20190207' and '20190210'
    and not exists 
    (
        select 1 from dbo.Credits c2
        where c2.UserId = c.UserId
            and c2.Status in (1, 3, 5)
    )
    and not exists 
    (
        select 1 from dbo.CreditStatusHistory csh
        where csh.CreditId = c.id
            and csh.Status = 3
    )
/
select 
    fu.id as ClientId
    , fu.LastName
    , fu.FirstName
    , fu.MobilePhone
    , fu.EmailAddress
    , reg.RegDate
    , e.Label as UserStatusKind
from dbo.FrontendUsers fu
inner join dbo.UserStatusHistory ush on ush.UserId = fu.id
    and ush.IsLatest = 1
inner join dbo.Enums e on e.Val = ush.UserStatus
    and e.Enum = 'UserStatusKind'
outer apply
(
    select top 1 ush.DateCreated as RegDate
    from dbo.UserStatusHistory ush
    where ush.UserId = fu.id
        and ush.UserStatus = 1
    order by ush.DateCreated
) reg
where reg.RegDate >= '20190207'