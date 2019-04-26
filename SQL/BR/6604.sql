declare
    @dateFrom date = '20190315'
    , @dateTo date = '20190415'
;


select
    p.ClientId as "Id клиента"
    , p.Productid as "id займа"
    , p.ContractNumber as "Номер договора"
    , p.ProductTypeName as "Тип займа"
    , p.StartedOn as "Дата старта займа"
    , p.Amount as "Сумма"
    , iif(ap.ProductNum = 1, 1, 0) as "Новый клиент"
    , sl.StartedOn as "Дата начала просрочки" 
    , p.StatusName as "Текущий статус"
    , s.Score as "Скорбалл"
    , p.ScheduleCalculationTypeName as "Тип графика ДЗ"
    , cl.ActionName as "Акция"
    , pay.AmountPaid as "Оплачено тело"
    , pay.TotalPaid as "Оплачено всего"
    , debt.AmountDebt as "Долг по телу"
    , debt.TotalDebt as "Долг всего"
from prd.vw_product p
inner join prd.vw_AllProducts ap on ap.ProductId = p.Productid
outer apply
(
    select top 1 crr.Score
    from cr.CreditRobotResult crr
    where crr.ClientId = p.ClientId
        and crr.Score > 0
        and crr.CreatedOn < p.CreatedOn
    order by crr.Score desc
) s
outer apply
(
    select
        sum(cb.TotalAmount) as AmountPaid
        , sum(cb.TotalDebt) as TotalPaid
    from bi.CreditBalance cb
    where cb.ProductId = p.Productid
        and cb.InfoType = 'payment'
) pay
outer apply
(
    select top 1 
        cb.TotalAmount * -1 as AmountDebt
        , cb.TotalDebt * -1 as TotalDebt 
    from bi.CreditBalance cb
    where cb.ProductId = p.Productid
        and cb.InfoType = 'debt'
    order by cb.DateOperation desc
) debt
outer apply
(
    select top 1 c.Description as ActionName
    from dbo.CustomListUsers clu
    inner join dbo.CustomList c on c.ID = clu.CustomlistID
    where clu.ClientId = p.ClientId
        and clu.DateCreated < p.CreatedOn
    order by clu.DateCreated desc
) cl
inner join prd.vw_statusLog sl on sl.ProductId = p.Productid
    and cast(sl.StartedOn as date) between @dateFrom and @dateTo
    and sl.Status = 4
where p.Status > 2
    and not exists
    (
        select 1 from prd.vw_statusLog sl2
        where sl2.ProductId = p.Productid
            and cast(sl2.StartedOn as date) between @dateFrom and @dateTo
            and sl2.Status = 4
            and sl2.StartedOn > sl.StartedOn
    )
