with dch as 
(
    select distinct
        cast(dch.DateCreated as date) as collectorDate
       ,dch.DebtorId
       ,d.CreditId
       ,c.UserId
    from dbo.DebtorCollectorHistory dch
    inner join dbo.Debtors d on d.Id = dch.DebtorId
    inner join dbo.Credits c on c.Id = d.CreditId
    where dch.CollectorId in
        (
            select
              u.UserId
            from CmsContent_LimeZaim.dbo.Users u
            join CmsContent_LimeZaim.dbo.UserGroupLinks ugl on ugl.UserId = u.UserId
            where ugl.UserGroupId = 44
        )
        and dch.DateCreated >= '20170601'
        and dch.DateCreated < '20170701'
)

,cs as 
(
    select distinct
        csh.CreditId
       ,cast(csh.DateStarted as date) as overdueStarted
       ,cast(csh_next.DateStarted as date) as overdueFinished
    from CreditStatusHistory csh
    left join CreditStatusHistory csh_next on csh_next.CreditId = csh.CreditId
        and csh_next.Id = (select min(csh_next1.id)
                           from CreditStatusHistory csh_next1
                           where csh_next1.CreditId = csh_next.CreditId
                               and csh_next1.status != 3
                               and csh_next1.id > csh.id)
    where csh.CreditId in (select creditId from dch)
        and csh.Status = 3
        and cast(csh.DateStarted as date) > dateadd(d, -4, '20170601')
        and cast(csh.DateStarted as date) <= dateadd(d, -4, '20170701')
)

,neededDCH  as 
(
    select 
        dch.*
       ,cs.overdueStarted
    from dch
    inner join cs on cs.CreditId = dch.CreditId
        and datediff(d, cs.overdueStarted, dch.collectorDate) + 1 = 4
        and (cs.overdueFinished >= dch.collectorDate or cs.overdueFinished is null)
)

,neededPayments as 
(
    select *
    from dbo.CreditPayments cp
    where cp.CreditId in (select CreditId from neededDCH)
      and 
        (
          exists (select 1 from dbo.DebtorInteractionHistory dih
                  inner join dbo.Debtors d on d.id = dih.DebtorId
                  where d.CreditId = cp.CreditId
                    and dateadd(hh, 3, dih.TimestampUtc) < cp.DateCreated)
         or 

           exists (select 1 from neededDCH
                   where cp.DateCreated between neededDCH.collectorDate and dateadd(d, 45, neededDCH.collectorDate))

        )
)

,d as 
(
    select CreditId,UserId,overdueStarted
    from neededDCH
    group by CreditId,UserId,overdueStarted
    having count(*) > 1
)

select *
from neededDCH