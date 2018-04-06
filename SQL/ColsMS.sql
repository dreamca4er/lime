drop table if exists #e
;

drop table if exists #col
;

select
    e.Id
    ,ClientId
    ,ProductId
    ,uc.ClaimValue as CollectorWhoSent
    ,e.CreatedOn as MessageSentMsg
into #e
from ecc.SmsCommunication e
inner join sts.UserClaims uc on uc.UserId = e.CreatedBy
    and uc.ClaimType = 'name'
inner join sts.UserRoles r on r.RoleId = 'A894C452-131A-4E65-8E15-62F0B56C0321'
    and r.UserId = e.CreatedBy
cross apply
(
    select top 1 
        sl.Status
    from prd.vw_statusLog sl
    where sl.ProductId = e.ProductId
        and sl.StartedOn < e.CreatedOn
    order by sl.CreatedOn desc
) sl
where e.CreatedOn >= '20180401'
    and sl.status = 4 
    and e.DeliveryStatus != 3
;

select
    e.*
    ,op.CollectorName
into #col
from #e e
outer apply
(
    select top 1 uc.ClaimValue as CollectorName
    from col.tf_op(cast(e.MessageSentMsg as date), cast(e.MessageSentMsg as date)) op
    inner join sts.UserClaims uc on uc.UserId = op.collectorid
        and uc.ClaimType = 'name'
    where op.productid = e.productid
    order by op.assigndate desc
) op

select *
from #col