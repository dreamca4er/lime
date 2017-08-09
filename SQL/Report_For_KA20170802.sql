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

--�������� Id �������� �� ������
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
	c.DogovorNumber as N'������� �����',	 
	c.UserId as N'ID �������',	 
	dh.CollectorId, 
	--fact.CityName as N'����� ������ �����',
	u.Lastname + ' ' + u.Firstname + ' ' + isnull(u.Fathername, '') as N'���',
	case when uc.[Gender] = 1 then N'�' else N'�' end as N'���',
	cast(uc.Birthday as datetime2) as N'���� ��������',	 
	case when len(isnull(uc.Passport, '')) = 0 
       then null 
       else left(replace(uc.Passport, ' ', ''), 4) 
  end as N'����� ��������',	 
	case when len(isnull(uc.Passport, '')) = 0 
       then null 
       else right(replace(uc.Passport, ' ', ''), 6) 
  end as N'����� ��������',	
	uc.[PassportIssuedBy] as N'��� ����� �������',	 
	uc.[PassportIssuedOn] as N'����� ����� �������',
	uai.RegRegion as N'�� - ������',
	uai.RegCityName as N'�� - ���������� �����',
	uai.RegStreetName as N'�� - �����',
	uai.RegHouse as N'�� - ���',
	uai.RegBlock as N'�� - ������',
	uai.RegFlat as N'�� - ��������',
	isnull(reglh.Postcode, '') as N'�� - �������� ������',
	uai.FactRegion as N'�� - ������',
	uai.FactCityName as N'�� - ���������� �����',
	uai.FactStreetName as N'�� - �����',
	uai.FactHouse as N'�� - ���',
	uai.FactBlock as N'�� - ������',
	uai.FactFlat as N'�� - ��������',
	isnull(factlh.Postcode, '') as N'�� - �������� ������',
	(select top(1) PhoneNumber
   from Phones 
   where isDeleted = 0 
     and UserId = c.UserId 
     and PhoneType = 1) as N'��������� �������',
	(select stuff((select ', ' +PhoneNumber 
                 from Phones 
                 where isDeleted = 0 
                   and UserId = c.UserId 
                   and PhoneType in (5, 6) 
                 for xml path ('')), 1, 1, '')) as N'�������������� �������',
	(select STUFF((select ', ' +PhoneNumber 
                 from Phones 
                 where isDeleted = 0 
                   and UserId = c.UserId 
                   and PhoneType not in (1, 5, 6) 
                 for xml path ('')), 1, 1, '')) as N'��������� ��������',
	c.DateCreated as N'���� ������ �����',
	c.Amount as N'�������� �����',

	csh.DateStarted as N'���� ������ �� ���������',
	datediff(Day, csh.DateStarted, getdate()) as N'���� � ���������',

	isnull(cb.Amount,0) - isnull(cp.Amount,0) 
	+ isnull(cb.PercentAmount,0) - isnull(cp.PercentAmount,0)
	+ isnull(cb.CommisionAmount,0) - isnull(cp.CommissionAmount,0)
	+ isnull(cb.PenaltyAmount,0) - isnull(cp.PenaltyAmount,0)
	+ isnull(cb.LongPrice,0) - isnull(cp.LongPrice,0) 
	+ isnull(cb.TransactionCosts,0) - isnull(cp.TransactionCosts,0) as N'����� �������������',

	isnull(cb.Amount,0) - isnull(cp.Amount,0) as N'������������� �� ��������� �����',
	isnull(cb.PercentAmount,0) - isnull(cp.PercentAmount,0) as N'������������� �� ���������',
	isnull(cb.CommisionAmount,0) - isnull(cp.CommissionAmount,0) as N'������������� �� ���������',
	isnull(cb.PenaltyAmount,0) - isnull(cp.PenaltyAmount,0) as N'������������� �� �������',
	isnull(cb.LongPrice,0) - isnull(cp.LongPrice,0) as N'������������� �� ���������',
	isnull(cb.TransactionCosts,0) - isnull(cp.TransactionCosts,0) as N'������������� �� �������������� ���������'

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
--����� ������� ��� ���������� �� - ��������� �������
left join Locations reglh on reglh.Id = reg.HouseId
--����� ������� ��� ���������� �� - ��������� �������
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
	--� �������� �� ������� �������� �� ������ �������� ��������, � ������� ������ ������ = �������
  and not exists (select 1 from DebtorInteractionHistory dih with (nolock)
                  where dih.debtorid = d.id
                    and dih.[Result] = @debtorResultClaim)
order by u.id
