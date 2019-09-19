update sc set IsDisabled = 1, ModifiedOn = getdate(), ModifiedBy = 0x44
from Collector.StrategyCondition sc
where StrategyId = 1
    and id between 2 and 6
;

insert collector.StrategyCondition
(
    StrategyId,ConditionType,ActionType,Value,Priority,SubPriority,GroupId,IsDisabled,ToGroupId,CreatedBy,CreatedOn
)
select *
    , cast(0x10269 as uniqueIdentifier) as CreatedBy
    , getdate() as CreatedOn
from
(
    values
    (1, 1, 1, 8, 1, 0, 1, 0, 3)
    , (1, 3, 1, 3, 2, 0, 3, 0, 2)
    , (1, 2, 1, 4, 2, 1, 3, 0, 2)
    , (1, 4, 1, 12, 2, 2, 3, 0, 2)
    , (1, 6, 1, 30, 2, 3, 2, 0, 3)
) v(StrategyId, ConditionType, ActionType, Value, Priority, SubPriority, GroupId, IsDisabled, ToGroupId)
;


update g
set name = iif(id = 2, N'ГТС(ДЗ)', N'Софт')
from collector."Group" g
where id in (2, 3)
;

