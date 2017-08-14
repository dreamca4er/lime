/****** Script for SelectTopNRows command from SSMS  ******/
--declare @NumberDays as int
--set @NumberDays = 30

select
    isnull(fu.Lastname,'') + ' ' + isnull(fu.Firstname,'') + ' ' + isnull(fu.Fathername,'') as N'ФИО'

    ,c.DogovorNumber  + N' от ' + convert(nvarchar, c.DateStarted, 104) as N'Номер и дата договора' 

    ,ua.StreetName COLLATE Latin1_General_CI_AI 
    + N',' + uai.RegHouse 
    + isnull(N' корп.' + uai.RegBlock, '')
    + isnull(N', кв. ' + uai.RegFlat, '')
    + ', ' + convert(nvarchar, ua.CityName)	as N'Адрес'
    ,coalesce(rklh."INDEX", rkls."INDEX", rklc."INDEX") as N'Индекс'
    ,cast(floor(lcb.Amount 
                + lcb.CommisionAmount 
                + lcb.LongPrice 
                + lcb.PenaltyAmount 
                + lcb.PercentAmount 
                + lcb.TransactionCosts) as int) as N'Сумма текущей задолженности'
from dbo.Debtors d
left join dbo.Credits c on c.Id = d.CreditId
left join (select max(Id) as LastBalanceId, CreditId  from CreditBalances group by CreditId) as lcbid on lcbid.CreditId = d.CreditId
left join dbo.CreditBalances lcb on lcb.id = lcbid.LastBalanceId
left join dbo.FrontendUsers fu on fu.Id = c.UserId
left join dbo.UserAdminInformation uai on uai.UserId = c.UserId
left join dbo.UserCards uc on uc.UserId = fu.Id
-- Рег адрес
left join dbo.UserAddresses ua on ua.Id = uc.RegAddressId 
left join dbo.Locations lh on lh.Id = ua.HouseId
left join dbo.KladrHouses rklh on rklh.CODE = lh.KladrCode
left join dbo.Locations ls on ls.Id = ua.StreetId
left join dbo.KladrStreets rkls on rkls.CODE = ls.KladrCode
left join dbo.Locations lc on lc.Id = ua.CityId
left join dbo.KladrLocations rklc on rklc.CODE = lc.KladrCode
-- Факт адрес
left join dbo.UserAddresses fua on fua.Id = uc.FactAddressId 
left join dbo.Locations flh on flh.Id = fua.HouseId
left join dbo.KladrHouses fklh on fklh.CODE = flh.KladrCode
left join dbo.Locations fls on fls.Id = fua.StreetId
left join dbo.KladrStreets fkls on fkls.CODE = fls.KladrCode
left join dbo.Locations flc on flc.Id = fua.CityId
left join dbo.KladrLocations fklc on fklc.CODE = flc.KladrCode
where c.status <> 1 
    and c.isfinished = 0
	-- фильтр по кол-ву дней просрочки (более или равно)
	and uai.LastCreditDatePay is not null 
    and datediff(dd, uai.LastCreditDatePay, getdate()) >= @NumberDays

union

select
    isnull(fu.Lastname,'') + ' ' + isnull(fu.Firstname,'') + ' ' + isnull(fu.Fathername,'') as N'ФИО'
      
    ,c.DogovorNumber  + N' от ' + convert(nvarchar, c.DateStarted, 104) as N'Номер и дата договора' 
      
    ,fua.StreetName COLLATE Latin1_General_CI_AI 
    + N',' + uai.FactHouse 
    + isnull(N' корп.' + uai.FactBlock, '')
    + isnull(N', кв. ' + uai.FactFlat, '')
    + ', ' + convert(nvarchar, ua.CityName) as N'Адресс'
    ,coalesce(fklh."INDEX", fkls."INDEX", fklc."INDEX") as N'Индекс'
    ,cast(floor(lcb.Amount 
                + lcb.CommisionAmount 
                + lcb.LongPrice 
                + lcb.PenaltyAmount 
                + lcb.PercentAmount 
                + lcb.TransactionCosts) as int) as N'Сумма текущей задолженности'
from dbo.Debtors d
left join dbo.Credits c on c.Id = d.CreditId
left join (select max(Id) as LastBalanceId, CreditId  from CreditBalances group by CreditId) as lcbid on lcbid.CreditId = d.CreditId
left join dbo.CreditBalances lcb on lcb.id = lcbid.LastBalanceId
left join dbo.FrontendUsers fu on fu.Id = c.UserId
left join dbo.UserAdminInformation uai on uai.UserId = c.UserId
left join dbo.UserCards uc on uc.UserId = fu.Id
-- Рег адрес
left join dbo.UserAddresses ua on ua.Id = uc.RegAddressId 
left join dbo.Locations lh on lh.Id = ua.HouseId
left join dbo.KladrHouses rklh on rklh.CODE = lh.KladrCode
left join dbo.Locations ls on ls.Id = ua.StreetId
left join dbo.KladrStreets rkls on rkls.CODE = ls.KladrCode
left join dbo.Locations lc on lc.Id = ua.CityId
left join dbo.KladrLocations rklc on rklc.CODE = lc.KladrCode
-- Факт адрес
left join dbo.UserAddresses fua on fua.Id = uc.FactAddressId 
left join dbo.Locations flh on flh.Id = fua.HouseId
left join dbo.KladrHouses fklh on fklh.CODE = flh.KladrCode
left join dbo.Locations fls on fls.Id = fua.StreetId
left join dbo.KladrStreets fkls on fkls.CODE = fls.KladrCode
left join dbo.Locations flc on flc.Id = fua.CityId
left join dbo.KladrLocations fklc on fklc.CODE = flc.KladrCode
where c.status <> 1 
    and c.isfinished = 0
	-- фильтр по кол-ву дней просрочки (более или равно)
	and uai.LastCreditDatePay is not null 
    and datediff(dd, uai.LastCreditDatePay, getdate()) >= @NumberDays 
    and uc.RegAddressIsFact = 0
Order by N'ФИО'