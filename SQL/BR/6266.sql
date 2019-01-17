with c as 
(
    select
        iif(c.TariffId = 4, N'ДЗ', N'КЗ') as "Тип займа"
        , cast(format(c.DateStarted, 'yyyyMM01') as date) as "Месяц" 
        , iif(right(c.DogovorNumber, 3) = '001', N'Новый', N'Повторный') as IsNewClient
        , w.Description as "Канал выдачи"
        , c.Amount as "Сумма займа"
        , c.Period as "Период"
        , c.id as "ID Займа"
    from dbo.Credits c
    inner join dbo.EnumDescriptions w on w.Value = c.Way
        and w.Name = 'MoneyWay'
    where c.DateStarted >= '20181001'
        and c.DateStarted < '20190101'
        and c.Status not in (5, 8)
)

,u as 
(
    select
        cast(format(DateRegistred, 'yyyyMM01') as date) as Mnth 
        , count(c.HadCredit) * 1.0 / count(*) as HadCredit
    from dbo.FrontendUsers u
    outer apply
    (
        select top 1 1 as HadCredit
        from c
        where c.Mnth = cast(format(DateRegistred, 'yyyyMM01') as date)
            and c.userId = u.id
    ) c
    where DateRegistred >= '20181001'
        and DateRegistred < '20190101'
    group by cast(format(DateRegistred, 'yyyyMM01') as date)
)

select
    c.Mnth as "Месяц"
    , c.ProductType as "Тип займа"
    , count(*) as "Кол-во займов" 
    , count(iif(c.IsNewClient = 1, 1, null)) as "Новых клиентов, шт"
    , count(iif(c.IsNewClient = 0, 1, null)) as "Повторных клиентов, шт"
    , count(iif(c.IsNewClient = 1, 1, null)) * 1.0 / sum(count(*)) over (partition by c.Mnth, c.ProductType) as "Новых клиентов, %"
    , count(iif(c.IsNewClient = 0, 1, null)) * 1.0 / sum(count(*)) over (partition by c.Mnth, c.ProductType) as "Повторных клиентов, %"
    , sum(iif(c.IsNewClient = 1, Amount, null)) as "Новых клиентов, руб"
    , sum(iif(c.IsNewClient = 0, Amount, null)) as "Повторных клиентов, руб"
    , count(iif(c.MoneyWay = N'На Qiwi-кошелек' and c.IsNewClient = 1, 1, null)) as "Новые клиенты на qiwi, шт"
    , count(iif(c.MoneyWay = N'На банковский счет' and c.IsNewClient = 1, 1, null)) as "Новые клиенты на bank, шт"
    , count(iif(c.MoneyWay = N'На карту' and c.IsNewClient = 1, 1, null)) as "Новые клиенты на card, шт"
    , count(iif(c.MoneyWay = N'На Яндекс.Деньги' and c.IsNewClient = 1, 1, null)) as "Новые клиенты на yandex, шт"
    , count(iif(c.MoneyWay = N'Через систему Contact' and c.IsNewClient = 1, 1, null)) as "Новые клиенты на contact, шт"
    , count(iif(c.MoneyWay = N'На Qiwi-кошелек' and c.IsNewClient = 0, 1, null)) as "Повторные клиенты на qiwi, шт"
    , count(iif(c.MoneyWay = N'На банковский счет' and c.IsNewClient = 0, 1, null)) as "Повторные клиенты на bank, шт"
    , count(iif(c.MoneyWay = N'На карту' and c.IsNewClient = 0, 1, null)) as "Повторные клиенты на card, шт"
    , count(iif(c.MoneyWay = N'На Яндекс.Деньги' and c.IsNewClient = 0, 1, null)) as "Повторные клиенты на yandex, шт"
    , count(iif(c.MoneyWay = N'Через систему Contact' and c.IsNewClient = 0, 1, null)) as "Повторные клиенты на contact, шт"
    , avg(iif(c.IsNewClient = 1, c.Amount, null)) as "Средняя сумма займа, новые"
    , avg(iif(c.IsNewClient = 0, c.Amount, null)) as "Средняя сумма займа, повторные"
    , avg(c.Period) as "Средний период"
from c
group by c.Mnth, c.ProductType