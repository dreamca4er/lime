SELECT 1 AS Id,1 AS CollectorToughness,4 AS DelayPeriodStart,50 AS DelayPeriodEnd,44 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,60 AS CollectorRightType
UNION ALL
SELECT 2 AS Id,2 AS CollectorToughness,51 AS DelayPeriodStart,1000 AS DelayPeriodEnd,45 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,61 AS CollectorRightType
UNION ALL
SELECT 3 AS Id,3 AS CollectorToughness,1000 AS DelayPeriodStart,1001 AS DelayPeriodEnd,46 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,62 AS CollectorRightType
UNION ALL
SELECT 4 AS Id,4 AS CollectorToughness,1002 AS DelayPeriodStart,365000 AS DelayPeriodEnd,47 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,63 AS CollectorRightType
UNION ALL
SELECT 5 AS Id,5 AS CollectorToughness,365001 AS DelayPeriodStart,null AS DelayPeriodEnd,60 AS CollectorRoleId,null AS DebtorMoveRuleClass,null AS CollectorGroupParameters,64 AS CollectorRightType
UNION ALL
SELECT 6 AS Id,0 AS CollectorToughness,1 AS DelayPeriodStart,3 AS DelayPeriodEnd,62 AS CollectorRoleId,'Fuse8.Websites.LimeZaim.BusinessFacade.DebtorMoveRules.MoveDebtorFromFakeCollectorsRule,Fuse8.Websites.LimeZaim.BusinessFacade' AS DebtorMoveRuleClass,'{"ContinualClientCreditCount":2,"MoveDelayForContinualClient":8}' AS CollectorGroupParameters,65 AS CollectorRightType
