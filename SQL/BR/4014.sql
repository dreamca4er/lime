select
    op.CollectorId
    ,uc.ClaimValue as CollectorName
    ,odc.OverdueDaysCategory
    ,count(*) as SmsCount
from #op op
inner join sts.UserClaims uc on uc.UserId = op.CollectorId
    and uc.ClaimType = 'name'
inner join ecc.SmsCommunication sc on sc.ClientId = op.ClientId
    and cast(sc.CreatedOn as date) between op.AssignDate and op.LastDayWasAssigned
    and sc.CreatedBy = op.CollectorId
    and cast(sc.CreatedOn as date) between '20180901' and '20180930'
outer apply
(
    select 
        case
            when datediff(d, op.OverdueStart, sc.CreatedOn) + 1 between 8 and 45 then '08-45'
            when datediff(d, op.OverdueStart, sc.CreatedOn) + 1 between 46 and 74 then '46-74'
            when datediff(d, op.OverdueStart, sc.CreatedOn) + 1 >= 75 then '75+'
        end as OverdueDaysCategory
) odc
group by op.CollectorId, uc.ClaimValue, odc.OverdueDaysCategory
