select
    c.UserId as "id Клиента"
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as "ФИО"
    ,isnull(ua.CityName, '') 
    + isnull(', ' + ua.StreetName, '') 
    + lower(isnull(N', д. ' + ua.House, ''))
    + lower(isnull(N', к. ' + ua.Block, ''))
    + lower(isnull(N', кв. ' + ua.Flat, '')) as "Адрес регистрации"
    ,isnull(ua.CityName, '') as "Город регистрации"
	,isnull(kh."index", ks."index") as "Индекс регистрации"
    ,left(uc.Passport, 4) as "Серия паспорта"
    ,right(uc.Passport, 6) as "Номер паспорта"
    ,format(uc.PassportIssuedOn, 'dd.MM.yyyy') as "Дата выдачи паспорта"
    ,uc.PassportIssuedBy as "Кем выдан паспорт"
    ,c.DogovorNumber as "Номер договора"
    ,format(c.DateCreated, 'dd.MM.yyyy') as "Дата договора"
    ,cb.Amount
    + cb.PercentAmount 
    + cb.CommisionAmount 
    + cb.PenaltyAmount 
    + cb.LongPrice 
    + cb.TransactionCosts as "Размер задолжности"
    ,cb.Amount as "Просроченная задолженность по основному долгу"
    ,cb.PercentAmount as "Просроченная задолженность по процентам"
    ,cb.PenaltyAmount as "Задолженность по штрафам"
    ,cb.LongPrice as "Просроченная задолжность по продлениям"
    ,cb.TransactionCosts as "Просроченная задолженность по оплате транзакционных издержек"
from dbo.Credits c
inner join dbo.UserAdminInformation uai on uai.UserId = c.UserId
    and datediff(d, uai.LastCreditDatePay, getdate()) >= 60 
    and datediff(d, uai.LastCreditDatePay, getdate()) <=
        case 
            when (
                    select t.Name
                    from dbo.Tariffs t
                    where t.id = 2
                  ) = 'Lime'
             then 360
             else datediff(d, uai.LastCreditDatePay, getdate())
        end
inner join dbo.UserCards uc on uc.UserId = c.UserId
inner join dbo.FrontendUsers fu on fu.Id = c.userid
left join dbo.UserAddresses ua on ua.Id = uc.RegAddressId
left join dbo.locations street on street.id = ua.streetid
left join dbo.locations house on  house.id = ua.houseid
left join kladrhouses kh  on kh.code = house.kladrcode
left join kladrstreets ks on ks.code = street.kladrcode
outer apply
(
    select top 1
        cb.Amount
        ,cb.PercentAmount
        ,cb.CommisionAmount
        ,cb.PenaltyAmount
        ,cb.LongPrice
        ,cb.TransactionCosts
    from dbo.CreditBalances cb
    where cb.CreditId = c.id
    order by cb.Date desc
) cb
where uc.IsFraud = 0
    and c.Status = 3
    and not exists (
                    select 1 from dbo.DebtorCollectorHistory dch
                    inner join dbo.Debtors d on d.Id = dch.DebtorId
                    where d.CreditId = c.id
                        and dch.IsLatest = 1
                        and (
                            (
                                select t.Name
                                from dbo.Tariffs t
                                where t.id = 2
                             ) = 'Lime'
                             and dch.CollectorId in (1163, 1195, 1239 ,1263 ,1264 -- Барсы
                                                    ,1229 -- Для передачи в суд
                                                    ,1049 -- Умершие
                                                    ,1237 -- Не оформлял
                                                     )
                             or (
                                    select t.Name
                                    from dbo.Tariffs t
                                    where t.id = 2
                                  ) = 'Konga'
                             and dch.CollectorId in (1049 -- Умершие
                                                    ,2234 -- Не оформлял
                                                    )
                             )
                    )
    and not exists (
                    select 1 from dbo.DebtorTransferCession dtc
                    inner join dbo.Debtors d on d.id = dtc.DebtorId
                    where d.CreditId = c.Id
                    )

