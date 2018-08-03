select
    case 
        when max(case when "key" = 'BalanceCalculation' then Value end) = 0
        then format(dateadd(hour, 4, max(case when "key" = 'BalanceCalculation' and Value = 0 then ModifiedOn end)), 'dd.MM HH:mm') 
        else N'В работе'
    end as BalanceCalculationStatus
    ,case
        when max(case when "key" = 'BalanceCalculation' then Value end) = 0
        then 1
        else 0
    end as BalanceCalculationIsOk
    ,case 
        when  max(case when "key" = 'Col.State' then Value end) = 0 
        then format(dateadd(hour, 4, max(case when "key" = 'Col.State' and Value = 0 then ModifiedOn end)), 'dd.MM HH:mm') 
        else N'В работе'
    end as CollectionStatus
    ,case
        when max(case when "key" = 'Col.State' then Value end) = 0
        then 1
        else 0 
    end as CollectionStatusIsOk
from cache.State
where "key" in ('BalanceCalculation', 'Col.State')
;