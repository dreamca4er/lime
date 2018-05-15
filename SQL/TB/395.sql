select 
    a.name
    ,a.collectorGroups
    ,op.ProductId
    ,sum(case when left(ac.Number, 5) in ('48801', '48802', '48803', N'штраф') then ac.SaldoNt end) * -1 as debt
from col.tf_op('19000101', getdate()) op
inner join sts.vw_admins a on a.id = op.CollectorId
inner join prd.LongTermCredit ltc on ltc.Id = op.ProductId
inner join acc.vw_acc ac on ac.ProductId = op.ProductId
where op.ActiveAssign = 1
    and a.collectorGroups not like '[DE]%'
group by
    a.name
    ,a.collectorGroups
    ,op.ProductId
order by a.collectorGroups, a.name
/
select
    u.username    
    ,ca.CreditId
    ,cb.debt - isnull(cp.PaidToday, 0) as Debt
    ,case 
        when ca.CollectorId in (
                                select AdminId
                                from dbo.AclAdminRoles as a
                                inner join dbo.AclRoles as r on a.AclRoleId = r.id
                                inner join dbo.AclAccessMatrix as m on m.AclRoleId = r.ID
                                where m.AclRightId in (60,61)
                                )
        then N'ОВ'
        when ca.CollectorId in (
                                select a.AdminId
                                from dbo.AclAdminRoles as a
                                inner join dbo.AclRoles as r on a.AclRoleId = r.id
                                inner join dbo.AclAccessMatrix as m on m.AclRoleId = r.ID
                                where m.AclRightId = 62
                                )
        then N'ГТС'
        when ca.CollectorId in (
                                select AdminId
                                from dbo.AclAdminRoles as a
                                inner join dbo.AclRoles as r on a.AclRoleId = r.id
                                inner join dbo.AclAccessMatrix as m on m.AclRoleId = r.ID
                                where m.AclRightId not in (60,61,62)
                                )
        then N'Пулы'
    end as CollectorGroup
from tf_getCollectorAssigns('19000101', getdate(), 0) ca
inner join dbo.Credits c on c.Id = ca.CreditId
    and c.TariffId = 4
left join syn_CmsUsers u on u.userid = ca.CollectorId
cross apply
(
    select top 1
        cb.Amount + cb.PercentAmount + cb.CommisionAmount + cb.PenaltyAmount + cb.LongPrice + cb.TransactionCosts as Debt
    from dbo.CreditBalances cb
    where cb.CreditId = c.id
    order by cb.Date desc
) cb
outer apply
(
    select
        sum(cp.Amount + cp.PercentAmount + cp.CommissionAmount + cp.PenaltyAmount + cp.LongPrice + cp.TransactionCosts) as PaidToday
    from dbo.CreditPayments cp
    where cp.CreditId = c.id
        and cp.DateCreated >= cast(getdate() as date)
) cp
where ca.CollectorAssignEnd is null
order by CollectorGroup, u.username  