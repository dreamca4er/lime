declare
    @dateFrom date = '20181001'
    , @dateTo date = '20181031'
;

select
    c.clientid as "Id клиента"
    , c.LastName as "Фамилия"
    , c.FirstName as "Имя"
    , c.FatherName as "Отчество"
    , c.PhoneNumber as "Телефон"
    , sl.ProductId as "Id займа"
    , p.ContractNumber as "Номер договора"
    , sl.StartedOn as "Дата начала просрочки"
    , cb.*
from prd.vw_statusLog sl
inner join prd.product p on p.id = sl.ProductId
inner join client.vw_client c on c.clientid = p.ClientId
outer apply
(
    select top 1 
        cb.TotalAmount * -1 as "Долг по телу"
        , cb.TotalPercent * -1 as "Долг по процентам"
        , cb.Commission * -1 as "Долг по коммисии"
        , cb.Fine * -1 as "Штраф"
    from bi.CreditBalance cb
    where cb.ProductId = sl.ProductId
        and cb.InfoType = 'debt'
        and cb.DateOperation <= dateadd(second, 1, cast(cast(sl.StartedOn as date) as datetime2))
    order by cb.DateOperation desc
) cb
where sl.Status = 4
    and sl.StartedOn between @dateFrom and @dateTo
    and not exists 
    (
        select 1 from prd.vw_statusLog sl2
        where sl2.ProductId = sl.ProductId
            and sl2.StartedOn between @dateFrom and @dateTo
            and sl2.StartedOn < sl.StartedOn
    )