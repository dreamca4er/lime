with lime as 
(
    SELECT 1 AS Id,1 AS CollectorToughness,8 AS DelayPeriodStart,69 AS DelayPeriodEnd,44 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,60 AS CollectorRightType
    UNION ALL
    SELECT 2 AS Id,2 AS CollectorToughness,70 AS DelayPeriodStart,1000 AS DelayPeriodEnd,45 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,61 AS CollectorRightType
    UNION ALL
    SELECT 3 AS Id,3 AS CollectorToughness,1000 AS DelayPeriodStart,1001 AS DelayPeriodEnd,46 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,62 AS CollectorRightType
    UNION ALL
    SELECT 4 AS Id,4 AS CollectorToughness,1002 AS DelayPeriodStart,365000 AS DelayPeriodEnd,47 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,63 AS CollectorRightType
    UNION ALL
    SELECT 5 AS Id,5 AS CollectorToughness,365001 AS DelayPeriodStart,null AS DelayPeriodEnd,60 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,64 AS CollectorRightType
    UNION ALL
    SELECT 6 AS Id,0 AS CollectorToughness,1 AS DelayPeriodStart,7 AS DelayPeriodEnd,62 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,65 AS CollectorRightType
)

,konga as 
(
    SELECT 1 AS Id,1 AS CollectorToughness,8 AS DelayPeriodStart,30 AS DelayPeriodEnd,44 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,60 AS CollectorRightType,'Konga' AS db
    UNION ALL
    SELECT 2 AS Id,2 AS CollectorToughness,31 AS DelayPeriodStart,1000 AS DelayPeriodEnd,45 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,61 AS CollectorRightType,'Konga' AS db
    UNION ALL
    SELECT 3 AS Id,3 AS CollectorToughness,1000 AS DelayPeriodStart,1001 AS DelayPeriodEnd,46 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,62 AS CollectorRightType,'Konga' AS db
    UNION ALL
    SELECT 4 AS Id,4 AS CollectorToughness,1002 AS DelayPeriodStart,365000 AS DelayPeriodEnd,47 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,63 AS CollectorRightType,'Konga' AS db
    UNION ALL
    SELECT 5 AS Id,5 AS CollectorToughness,365001 AS DelayPeriodStart,null AS DelayPeriodEnd,60 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,64 AS CollectorRightType,'Konga' AS db
    UNION ALL
    SELECT 6 AS Id,0 AS CollectorToughness,1 AS DelayPeriodStart,7 AS DelayPeriodEnd,62 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,65 AS CollectorRightType,'Konga' AS db
)

,mango as 
(
SELECT 1 AS Id,1 AS CollectorToughness,1 AS DelayPeriodStart,50 AS DelayPeriodEnd,44 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,60 AS CollectorRightType,'Mango' AS db
UNION ALL
SELECT 2 AS Id,2 AS CollectorToughness,51 AS DelayPeriodStart,10000 AS DelayPeriodEnd,45 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,61 AS CollectorRightType,'Mango' AS db
UNION ALL
SELECT 3 AS Id,3 AS CollectorToughness,10001 AS DelayPeriodStart,30000 AS DelayPeriodEnd,46 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,62 AS CollectorRightType,'Mango' AS db
UNION ALL
SELECT 4 AS Id,4 AS CollectorToughness,30001 AS DelayPeriodStart,40000 AS DelayPeriodEnd,47 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,63 AS CollectorRightType,'Mango' AS db
UNION ALL
SELECT 8 AS Id,5 AS CollectorToughness,40001 AS DelayPeriodStart,null AS DelayPeriodEnd,60 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,64 AS CollectorRightType,'Mango' AS db
UNION ALL
SELECT 9 AS Id,0 AS CollectorToughness,0 AS DelayPeriodStart,0 AS DelayPeriodEnd,62 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,65 AS CollectorRightType,'Mango' AS db
)
/*
update cg
set 
    cg.DelayPeriodStart = lime.DelayPeriodStart
    ,cg.DelayPeriodEnd = lime.DelayPeriodEnd
--select
--    cg.*
--    ,lime.DelayPeriodStart
--    ,lime.DelayPeriodEnd
from dbo.CollectorGroups cg
inner join lime on lime.CollectorToughness = cg.CollectorToughness


select
    CollectorToughness,DelayPeriodStart,DelayPeriodEnd,CollectorRoleId,DebtorMoveRuleClass,CollectorGroupParameters,CollectorRightType
from dbo.CollectorGroups

union

select
    CollectorToughness,DelayPeriodStart,DelayPeriodEnd,CollectorRoleId,DebtorMoveRuleClass,CollectorGroupParameters,CollectorRightType
from lime
*/

/*
Mango
 roleName                  DelayPeriodStart     DelayPeriodEnd     collectorCnt    
 ------------------------  -------------------  -----------------  ------ 
 CollectorPrimaryDispatch  1                    7                  1      
 Collector1                8                    69                 7      
 Collector2                70                   1000               1      
 Collector3                1000                 1001               0      
 Collector4                1002                 365000             0      
 Внешний коллектор         365001               (null)             1         

Konga
 roleName                  DelayPeriodStart     DelayPeriodEnd     collectorCnt    
 ------------------------  -------------------  -----------------  ------ 
 CollectorPrimaryDispatch  1                    7                  1      
 Collector1                8                    69                 16     
 Collector2                70                   1000               0      
 Collector3                1000                 1001               0      
 Collector4                1002                 365000             4      
 Внешний коллектор         365001               (null)             6      

Lime
 roleName                  DelayPeriodStart     DelayPeriodEnd     collectorCnt    
 ------------------------  -------------------  -----------------  ------ 
 CollectorPrimaryDispatch  1                    7                  1      
 Collector1                8                    69                 33     
 Collector2                70                   1000               1      
 Collector3                1000                 1001               0      
 Collector4                1002                 365000             6      
 Внешний коллектор         365001               (null)             9      

       
*/

select
    ar.Name as roleName
    ,cg.DelayPeriodStart
    ,cg.DelayPeriodEnd
    ,count(distinct u.userid) as cnt
from dbo.AclAccessMatrix aam
inner join dbo.CollectorGroups cg on cg.CollectorRightType = aam.AclRightId
left join dbo.AclAdminRoles aar on aar.AclRoleId = aam.AclRoleId
left join dbo.AclRoles ar on ar.Id = aam.AclRoleId
left join syn_CmsUsers u on u.userid = aar.AdminId
group by 
    ar.Name
    ,cg.DelayPeriodStart
    ,cg.DelayPeriodEnd
    ,cg.CollectorToughness
order by cg.CollectorToughness