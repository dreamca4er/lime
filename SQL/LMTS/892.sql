
--drop table if exists #lmts892;

select
    dch.*
    ,c.id as creditid
    ,c.UserId as clientid
    ,c.Status
    ,datediff(d, uai.LastCreditDatePay,getdate()) as overdueDays
--into #lmts892
--update dch
--set islatest = 0
from dbo.DebtorCollectorHistory dch
inner join dbo.Debtors d on d.id = dch.DebtorId
inner join dbo.Credits c on c.Id = d.CreditId
inner join dbo.UserAdminInformation uai on uai.UserId = c.UserId
where dch.IsLatest = 0
    and dch.CollectorId in
                    (
                        select AdminId
                        from dbo.AclAdminRoles
                        where AclRoleId = 6
                    )
    and datediff(d, uai.LastCreditDatePay,getdate()) >= 110
;

select *
from #lmts892