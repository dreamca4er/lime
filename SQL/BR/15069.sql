select
    p.ClientId
    , p.Productid
    , p.StartedOn
    , cast(p.DatePaid as date) as DatePaid
    , p.StatusName
    , p.ProductTypeName
    , p.Amount
    , crr.Score
    , os.FirstOverdueStart
    , debt.*
    , iif(osn.Status = 4, datediff(d, osn.StatusStart, getdate()) + 1, 0) as CurrentOverdueDays
from prd.vw_product p
outer apply
(
    select top 1 sl.StartedOn as FirstOverdueStart
    from prd.vw_statusLog sl
    where sl.ProductId = p.Productid
        and sl.Status = 4
    order by sl.StartedOn desc
) os
outer apply
(
    select top 1 
        sl.StartedOn as StatusStart
        , sl.Status
    from prd.vw_statusLog sl
    where sl.ProductId = p.Productid
    order by sl.StartedOn desc
) osn
outer apply
(
    select top 1 
        coalesce(crr.ShortTermScore, crr.LongTermScore, crr.Score) as Score
    from cr.CreditRobotResult crr
    where crr.ClientId = p.ClientId
        and crr.CreatedOn < p.CreatedOn
    order by crr.CreatedOn desc
) crr
outer apply
(
    select top 1 
        cb.TotalAmount * -1 as TotalAmount
        , cb.TotalPercent * -1 as TotalPercent
        , cb.Fine * -1 as Fine
        , cb.Commission * -1 as Commission
    from bi.CreditBalance cb
    where cb.ProductId = p.Productid
        and cb.InfoType = 'debt'
    order by cb.DateOperation desc
) debt
where p.status > 2
    and (p.StartedOn <= '20190930' and p.DatePaid is null or p.DatePaid >= '20190701')