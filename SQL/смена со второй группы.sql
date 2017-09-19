select 
    ca.*
    ,uai.LastCreditDatePay
    ,dch.CollectorId as prevCollectorId
    ,dch.id as prevAssignId
    ,u.username
    ,datediff(d, overdueStart, getdate()) + 1 as overdueDays
--into #ca
from dbo.tf_getCollectorAssigns(cast(getdate() as date), cast(getdate() as date), 1038) ca
inner join dbo.UserAdminInformation uai on uai.userid = ca.userid
inner join dbo.Debtors d on d.CreditId = ca.creditid
inner join dbo.DebtorCollectorHistory dch on dch.DebtorId = d.id
    and dch.id = (
                    select max(dch1.id)
                    from dbo.DebtorCollectorHistory dch1
                    where dch1.DebtorId = d.id
                        and dch1.id < ca.assignid
                  )
inner join syn_CmsUsers u on u.userid = dch.collectorid
where datediff(d, overdueStart, getdate()) + 1 >= 51
    and datediff(d, overdueStart, getdate()) + 1 <= 69
    and ca.collectorAssignStart >= cast(getdate() - 1 as date)
    and dch.CollectorId != 1351
    and collectorAssignEnd is null
;
/*
update dch
set dch.isLatest = 1
--select dch.*
from dbo.DebtorCollectorHistory dch
inner join #ca ca on ca.prevAssignId = dch.id
;

delete 
--select *
from dbo.DebtorCollectorHistory
where id in (
              select assignid from #ca ca 
             )
*/