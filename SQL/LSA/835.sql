-- sms
select
    us.Id as userId
from dbo.vw_UserState us
inner join dbo.FrontendUsers fu on fu.Id = us.Id
outer apply
(
    select top 1 
        cast(max(c.DatePaid) as date) as DatePaid
    from dbo.Credits c
    where c.UserId = us.Id
        and c.Status = 2
) lc
where fu.ConsentReceived = 1
    -- and us.CurrentUserStatus = 11 and lc.DatePaid between '20181201' and '20190211'
    -- and us.CurrentUserStatus = 6 and lc.DatePaid is not null
    and us.CurrentUserStatus = 6 and lc.DatePaid is null
/

-- email
select
    fu.id as UserId
    , fu.FirstName
    , fu.LastName
    , nullif(iif(ltrim(rtrim(fu.SecondName)) in ('null', 'none'), null, ltrim(rtrim(fu.SecondName))), '') as SecondName
    , fu.EmailAddress
from dbo.vw_UserState us
inner join dbo.FrontendUsers fu on fu.Id = us.Id
outer apply
(
    select top 1 
        cast(max(c.DatePaid) as date) as DatePaid
    from dbo.Credits c
    where c.UserId = us.Id
        and c.Status = 2
) lc
where fu.ConsentReceived = 1
    and fu.EmailAddress != 'none@none.com'
    -- and us.CurrentUserStatus = 1
    -- and us.CurrentUserStatus = 11 and lc.DatePaid between '20180701' and '20181130'
    -- and us.CurrentUserStatus = 11 and lc.DatePaid between '20181201' and '20190211'
    -- and us.CurrentUserStatus = 11 and lc.DatePaid is null
    -- and us.CurrentUserStatus = 11 and lc.DatePaid is not null
    -- and us.CurrentUserStatus = 6 and lc.DatePaid is not null