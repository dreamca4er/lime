--declare @delaydaysfrom int = null
--declare @delaydaysto int = null
--declare @transferfrom datetime2 = null
--declare @transferto datetime2 = null
--declare @recallfrom datetime2 = null
--declare @recallto datetime2 = null
--declare @isFraud bit = null
--declare @transfertype int = null
--declare @collectorid int = 1174
--declare @clientid nvarchar(max) = null

--Извлечем Id клиентов из строки
declare @xml xml
declare @clientIdList table
(
	[ClientId] int not null
)
set @xml = cast(('<X>' + replace(@clientid, ',', '</X><X>') + '</X>') as xml)
insert into @clientIdList
	select C.value('.', 'int') from @xml.nodes('X') as X(C)

declare @debtorStatusFullyPaid int = 3, @debtorResultClaim int = 13;

with lastCPS as 
(
  select
    cps.CreditId
   ,max(cps.id) as lastId
  from dbo.CreditPaymentSchedules cps
  group by CreditId
)

,dhPrev as 
(
  select
    dch.DebtorId
   ,max(dch.DateCreated) as DateCreated
  from dbo.DebtorCollectorHistory dch
  where dch.IsLatest != 1
  group by dch.DebtorId
)

,lastOverdueDate as 
(
  select
    csh.CreditId
   ,max(DateStarted) as DateStarted
  from dbo.CreditStatusHistory csh
  where csh.Status = 3
  group by CreditId
)

,lastCB as 
(
  select
    cb.CreditId
   ,cb.Amount
   ,cb.PercentAmount
   ,cb.CommisionAmount
   ,cb.PenaltyAmount
   ,cb.LongPrice
   ,cb.TransactionCosts
  from dbo.CreditBalances cb
  where cb.Id = (select max(id) from dbo.CreditBalances cb1
                 where cb1.CreditId = cb.CreditId)
)

select 
	c.DogovorNumber as N'Договор займа',	 
	c.UserId as N'ID клиента',	 
	dh.CollectorId, 
	--fact.CityName as N'Город выдачи займа',
	u.Lastname + ' ' + u.Firstname + ' ' + isnull(u.Fathername, '') as N'ФИО',
	case when uc.[Gender] = 1 then N'м' else N'ж' end as N'Пол',
	cast(uc.Birthday as datetime2) as N'Дата рождения',	 
	case when len(isnull(uc.Passport, '')) = 0 
       then null 
       else left(replace(uc.Passport, ' ', ''), 4) 
  end as N'Серия паспорта',	 
	case when len(isnull(uc.Passport, '')) = 0 
       then null 
       else right(replace(uc.Passport, ' ', ''), 6) 
  end as N'Номер паспорта',	
	uc.[PassportIssuedBy] as N'Кем выдан паспорт',	 
	uc.[PassportIssuedOn] as N'Когда выдан паспорт',
	uai.RegRegion as N'АР - Регион',
	uai.RegCityName as N'АР - Населенный пункт',
	uai.RegStreetName as N'АР - Улица',
	uai.RegHouse as N'АР - Дом',
	uai.RegBlock as N'АР - Корпус',
	uai.RegFlat as N'АР - Квартира',
	isnull(reglh.Postcode, '') as N'АР - Почтовый индекс',
	uai.FactRegion as N'АФ - Регион',
	uai.FactCityName as N'АФ - Населенный пункт',
	uai.FactStreetName as N'АФ - Улица',
	uai.FactHouse as N'АФ - Дом',
	uai.FactBlock as N'АФ - Корпус',
	uai.FactFlat as N'АФ - Квартира',
	isnull(factlh.Postcode, '') as N'АФ - Почтовый индекс',
	(select top(1) PhoneNumber
   from Phones 
   where isDeleted = 0 
     and UserId = c.UserId 
     and PhoneType = 1) as N'Мобильный телефон',
	(select stuff((select ', ' +PhoneNumber 
                 from Phones 
                 where isDeleted = 0 
                   and UserId = c.UserId 
                   and PhoneType in (5, 6) 
                 for xml path ('')), 1, 1, '')) as N'Дополнительный телефон',
	(select STUFF((select ', ' +PhoneNumber 
                 from Phones 
                 where isDeleted = 0 
                   and UserId = c.UserId 
                   and PhoneType not in (1, 5, 6) 
                 for xml path ('')), 1, 1, '')) as N'Известные телефоны',
	c.DateCreated as N'Дата выдачи займа',
	c.Amount as N'Выданная сумма',

	csh.DateStarted as N'Дата выхода на просрочку',
	datediff(Day, csh.DateStarted, getdate()) as N'Дней в просрочке',

	isnull(cb.Amount,0) - isnull(cp.Amount,0) 
	+ isnull(cb.PercentAmount,0) - isnull(cp.PercentAmount,0)
	+ isnull(cb.CommisionAmount,0) - isnull(cp.CommissionAmount,0)
	+ isnull(cb.PenaltyAmount,0) - isnull(cp.PenaltyAmount,0)
	+ isnull(cb.LongPrice,0) - isnull(cp.LongPrice,0) 
	+ isnull(cb.TransactionCosts,0) - isnull(cp.TransactionCosts,0) as N'ИТОГО задолженность',

	isnull(cb.Amount,0) - isnull(cp.Amount,0) as N'Задолженность по основному долгу',
	isnull(cb.PercentAmount,0) - isnull(cp.PercentAmount,0) as N'Задолженность по процентам',
	isnull(cb.CommisionAmount,0) - isnull(cp.CommissionAmount,0) as N'Задолженность по комиссиям',
	isnull(cb.PenaltyAmount,0) - isnull(cp.PenaltyAmount,0) as N'Задолженность по штрафам',
	isnull(cb.LongPrice,0) - isnull(cp.LongPrice,0) as N'Задолженность по продлению',
	isnull(cb.TransactionCosts,0) - isnull(cp.TransactionCosts,0) as N'Задолженность по транзакционным издержкам'

from [dbo].[Debtors] d
inner join [dbo].[DebtorCollectorHistory] dh on d.Id = dh.DebtorId 
  and dh.IsLatest = 1
inner join [dbo].[Credits] c on c.Id = d.CreditId
inner join lastCB cb on cb.CreditId = c.Id 
inner join lastCPS on lastCPS.CreditId = c.id
inner join [dbo].[CreditPaymentSchedules] cps ON cps.id = lastCPS.lastId
inner join [dbo].[FrontendUsers] u on u.Id = c.UserId
inner join [dbo].[UserAdminInformation] uai on uai.UserId = u.Id
inner join [dbo].[UserCards] uc on uc.UserId = u.Id
left join [dbo].[UserAddresses] fact on fact.Id = uc.[FactAddressId]
left join [dbo].[UserAddresses] reg on reg.Id = uc.[RegAddressId]
left join dhPrev on dhPrev.DebtorId = d.id
left join lastOverdueDate csh on csh.CreditId = d.CreditId
--далее таблицы для извлечения АР - почтового индекса
left join Locations reglh on reglh.Id = reg.HouseId
--далее таблицы для извлечения АФ - почтового индекса
left join Locations factlh on factlh.Id = fact.HouseId
--payments
outer apply (
	select 
    sum(Amount) as Amount
   ,sum(PercentAmount) as PercentAmount
   ,sum(CommissionAmount) as CommissionAmount
   ,sum(PenaltyAmount) as PenaltyAmount
   ,sum(LongPrice) as LongPrice
   ,sum(TransactionCosts) as TransactionCosts
	from [dbo].[CreditPayments] 
	group by CreditId, cast(DateCreated AS date) 
	having cast(DateCreated AS date) = cast(getdate() as date) and CreditId = c.Id
) as cp

WHERE d.[Status] <> @debtorStatusFullyPaid
  and (@clientid is null or @clientid = N'' or c.[UserId] in (select [ClientId] from @clientIdList))
	and (@delaydaysfrom is null or @delaydaysfrom <= isnull(datediff(day, csh.DateStarted, getdate()), 0))
	and (@delaydaysto is null or @delaydaysto >= isnull(datediff(day, csh.DateStarted, getdate()), 0))

	and (@transferfrom is null or (dh.DateCreated is not null and @transferfrom <= dh.DateCreated))
	and (@transferto is null or (dh.DateCreated is not null and @transferto >= dh.DateCreated))

	and (@recallfrom is null or (dhPrev.DateCreated is not null and @recallfrom <= dhPrev.DateCreated))
	and (@recallto is null or (dhPrev.DateCreated is not null and @recallto >= dhPrev.DateCreated))

	and (@isFraud is null or isnull(uc.IsFraud, 0) = @isFraud)
	and (@transfertype is null or @transfertype = 1)

	and (@collectorid is null or @collectorid = 0 or dh.[CollectorId] = @collectorid)
	--в выгрузку по каждому договору не должны попадать телефоны, у которых Статус звонка = «Жалоба»
  and not exists (select 1 from DebtorInteractionHistory dih with (nolock)
                  where dih.debtorid = d.id
                    and dih.[Result] = @debtorResultClaim)
order by u.id
