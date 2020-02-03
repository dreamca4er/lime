insert collector."Group"
(
    Name,IsDummy,IsSkg,CreatedOn,CreatedBy
)
select *, getdate() as CreatedOn, 0x44 as CreatedBy
from
(
    values
    (N'Буфер Правеж', 1, 0)
    , (N'Буфер ЮВС', 1, 0)
) v(Name, IsDummy, IsSkg)
where not exists
    (
        select 1 from collector."Group" cg
        where cg.Name = v.Name
    )
;

insert collector.StrategyCondition
(
    StrategyId,ConditionType,ActionType,Value,Priority,SubPriority,IsDisabled,CreatedOn,CreatedBy,ToGroupId
)
select 
    s.Id as StrategyId
    , 7 as ConditionType
    , 1 as ActionType
    , c.Value
    , c.Value as Priority
    , 0 as SubPriority
    , 0 as IsDisabled
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , g.Id as ToGroupId
from Collector.Strategy s, (values (11), (12)) c(Value)
inner join Collector."Group" g on c.Value = 11 and g.Name = N'Буфер Правеж'
    or c.Value = 12 and g.Name = N'Буфер ЮВС'
where s.Name in (N'Strat 0 ДЗ',N'Strat 3 КЗ',N'Strat 2 КЗ',N'Strat 1 КЗ')
    and not exists
    (
        select 1 from collector.StrategyCondition sc
        where sc.ConditionType = 7
    )
