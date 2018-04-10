select
    op.OverdueProductId
    ,op.CollectorId
    ,uc.claimvalue as CollectorName 
    ,op.clientid
    ,op.ProductId
    ,cast(op.AssignDate as date) as AssignDate
    ,cast(op.LastDayWasAssigned as date) as LastDayWasAssigned
    ,cast(sl.StartedOn as date) as DatePaid
    ,datediff(d, op.LastDayWasAssigned, sl.StartedOn) as DaysBetween
--update oprod set oprod.AssignedDays = oprod.AssignedDays + datediff(d, op.LastDayWasAssigned, sl.StartedOn)
--into dbo.tb343
from col.tf_op('19000101', getdate()) op
inner join col.OverdueProduct oprod on oprod.id = op.OverdueProductId
cross apply
(
    select top 1 os.StartedOn, os.Status
    from prd.vw_statusLog os
    where os.ProductId = op.productid
        and os.Status != 5
    order by os.StartedOn desc
) os
inner join prd.vw_statusLog sl on sl.ProductId = op.ProductId
    and sl.Status = 5
inner join sts.UserClaims uc on uc.userid = op.collectorid
    and uc.claimtype = 'name'
where not exists 
            (
                select 1 from col.tf_op('19000101', getdate()) op1
                where op1.productid = op.productid
                    and op1.Assigndate > op.Assigndate
            )
    and op.LastDayWasAssigned < sl.StartedOn
    and os.Status = 4
    and op.CollectorId not in ('21CB2B99-B129-4794-B1CA-396172409DB2', '6AC8499E-B1DA-4C3C-8C00-BAF6488E3207', 'DE66079B-D589-406B-AB41-CA1E1588F84F')
