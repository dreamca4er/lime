select
    p.ClientId
    , p.Productid
    , p.ContractNumber
    , p.ProductTypeName
    , p.StartedOn
    , p.Amount
    , iif(ap.ProductNum = 1, 1, 0) as IsNew
    , sl.StartedOn as OverdueStart 
    , p.StatusName
    , s.Score
    , p.ScheduleCalculationTypeName
    , cl.ActionName
    , pay.*
    , debt.*
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
    and cast(sl.StartedOn as date) between '20190120' and '20190131'
    and sl.Status = 4
where p.Status > 2