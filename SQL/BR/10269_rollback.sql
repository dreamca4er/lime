update g
set name = iif(id = 2, N'Коллекшн(ДЗ)', N'Софт(КЗ)')
from collector."Group" g
where id in (2, 3)
;

delete
from collector.StrategyCondition
where CreatedBy = 0x10269
;

update sc set IsDisabled = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from Collector.StrategyCondition sc
where StrategyId = 1
    and id between 2 and 6
;