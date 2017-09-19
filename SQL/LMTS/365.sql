select
    us.Id as "id Клиента"
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as "ФИО"
    ,fu.mobilephone as "Телефон"
    ,fu.emailaddress as "Email"
from dbo.vw_UserStatuses us
inner join dbo.FrontendUsers fu on fu.Id = us.Id
left join dbo.UserCards uc on uc.UserId = us.Id
left join dbo.UserAddresses ua on ua.Id = uc.RegAddressId
left join dbo.UserAddresses uaf on uaf.Id = uc.FactAddressId
where us.State not in (6, 12)
    and fu.DateRegistred >= '20170101'
    and coalesce(ua.CityId, uaf.CityId) = 6062 -- Mango: 6062 --Konga: 5703 -- Lime: 6062
order by fu.id desc

