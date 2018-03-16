select
    op.id
    ,op.ProductId
    ,op.CollectorId
    ,op.CreatedOn
    ,op.Date
    ,op.AssignedDays
    ,sl.StatusName
    ,sl.StartedOn
    ,op.IsDeleted
--delete op
from col.OverdueProduct op
outer apply
(
    select top 1
        sl.Status
        ,sl.StartedOn
        ,sl.StatusName
    from prd.vw_statusLog sl
    where sl.ProductId = op.ProductId
        and sl.StartedOn <= op.Date
    order by sl.StartedOn desc
) sl
where sl.Status is null
    or sl.status != 4
