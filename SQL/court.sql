select
    fu.id as "ID"
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as "ФИО"
    ,'' as "Регион телефона"
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as "Первоначальный кредитор"
    ,c.DogovorNumber as "Номер договора займа"
    ,c.DateCreated as "Дата договора займа"
    ,edu.Description as "Канал выдачи займа"
    ,fu.MobilePhone as "Мобильный телефон"
    ,c.DatePaid  as "Дата гашения займа"
    ,''as "Диапазон просрочки, дней"
    ,c.Amount as "Сумма займа по договору"
    ,cb.Amount - isnull(cp.Amount, 0) as "Остаток тела долга"
    ,c.Period as "Срок займа, дней"
    ,cb.PercentAmount - isnull(cb.PercentAmount, 0) as "Проценты (ост)"
    ,cb.PenaltyAmount - isnull(cb.PenaltyAmount, 0) as "Штраф (ост)"
    ,us.State as "Статус клиента"
    ,ua.CityName + isnull(', ' + ua.StreetName, '') 
     + N', д. ' + ua.House 
     + isnull(N', к. ' + ua.Block, '')
     + isnull(N', кв. ' + ua.Flat, '') as "Адрес регистрации"
    ,uaf.CityName + isnull(' ' + uaf.StreetName, '') 
     + N', д. ' + uaf.House 
     + isnull(N', к. ' + uaf.Block, '')
     + isnull(N', кв. ' + uaf.Flat, '') as "Адрес фактического места жительства"
    ,uc.Passport as "серия номер (по паспорту)"
    ,uc.PassportIssuedOn as "дата выдачи (по паспорту)"
    ,uc.PassportIssuedBy as "кем выдан (по паспорту)"
    ,uc.Birthday as "Дата рождения заемщика"
    ,uc.BirthPlace as "Место рождения"
    ,uc.Gender as "Пол"
    ,datediff(d, fu.Birthday, getdate()) / 365 as "Возраст клиента"
    ,'' as "рабочий статус должника"
    ,uc.OrganizationName as "место работы"
    ,'' as "Место работы(адрес)"
    ,uc.Position as "должность"
    ,uc.Income as "Ежемесячный доход"
    ,uc.IsCourtOrder as "получен судебный приказ"
    ,uc.IsDied as "должник умер"
    ,fu.BankruptType as "этап банкротства"
from dbo.FrontendUsers fu with (nolock)
inner join dbo._court l with (nolock) on l.id = fu.id
inner join dbo.Credits c with (nolock) on c.DogovorNumber = l.contractNumber
    and c.Status != 8
inner join dbo.EnumDescriptions edu with (nolock) on edu.Value = c.Way
    and edu.Name = 'MoneyWay'
inner join dbo.vw_UserStatuses us with (nolock) on us.Id = fu.id
inner join dbo.UserCards uc with (nolock) on uc.UserId = fu.id
inner join dbo.UserAddresses ua with (nolock) on ua.Id = uc.RegAddressId
left join dbo.UserAddresses uaf with (nolock) on uaf.Id = uc.FactAddressId
outer apply
(
    select top 1 
        Amount
        ,PercentAmount
        ,PenaltyAmount
    from dbo.CreditBalances cb  with (nolock)
    where cb.CreditId = c.id
    order by cb.Date desc
) as cb
outer apply
(
    select 1
        Amount
        ,PercentAmount
        ,PenaltyAmount
    from dbo.CreditPayments cp with (nolock)
    where cp.CreditId = c.id
        and cp.DateCreated >= cast(getdate() as date)
) as cp
