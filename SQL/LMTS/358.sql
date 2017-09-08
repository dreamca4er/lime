with dch as 
(
select
    fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,c.userid
    ,u.Username as collector
    ,dch.CollectorId
    ,d.CreditId
    ,dch.DateCreated as collectorAssignStart
    ,nullif(lead(dch.DateCreated, 1, 0) over (partition by d.CreditId order by dch.DateCreated), '19000101') as collectorAssignEnd
    ,dch.CreatedByUserId as collectorAssignedBy
    ,nullif(lead(dch.CreatedByUserId, 1, 0) over (partition by d.CreditId order by dch.DateCreated), '0') as collectorDisAssignBy
    ,cs.activeStart
from dbo.DebtorCollectorHistory dch
inner join dbo.Debtors d on d.Id = dch.DebtorId
inner join dbo.credits c on c.Id = d.CreditId
inner join CmsContent_LimeZaim.dbo.users u on u.UserId = dch.CollectorId
inner join dbo.FrontendUsers fu on fu.Id = c.userid
outer apply 
(
    select min(csh.DateStarted) as activeStart
    from dbo.CreditStatusHistory csh
    where csh.CreditId = c.id
        and csh.Status = 1
        and csh.DateStarted > dch.DateCreated
) cs
)

select
    dch.userid
    ,dch.fio
    ,dch.collector
    ,dch.collectorAssignStart
    ,case 
        when activeStart < collectorAssignEnd or collectorAssignEnd is null 
        then activeStart
        else collectorAssignEnd
    end as collectorAssignEnd
    ,case 
        when collectorDisAssignBy = 1 or activeStart < collectorAssignEnd or collectorAssignEnd is null 
        then N'Авто'
        else N'Вручную'
    end as disassignedBy
from dch
where cast(collectorAssignStart as date) between '20170907' and '20170908'
    or cast(collectorAssignEnd as date) between '20170907' and '20170908'