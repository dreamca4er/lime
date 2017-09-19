with u as 
(
    select
        u.userid
        ,row_number() over (order by userid) as rn
    from syn_CmsUsers u
    inner join AclAdminRoles aar on aar.AdminId = u.userid
        and aar.AclRoleId = 4
)

,assigns as 
(
    select
        debtorid
        ,dch.Id as assignId
        ,row_number() over (order by dch.Id) as rn
    from dbo.Credits c
    inner join dbo.UserAdminInformation uai on uai.UserId = c.UserId
        and datediff(d, uai.LastCreditDatePay, getdate()) >= 31
        and datediff(d, uai.LastCreditDatePay, getdate()) <= 50
    inner join dbo.debtors d on d.creditid = c.id
    inner join dbo.DebtorCollectorHistory dch on dch.DebtorId = d.id
        and dch.islatest = 1
        and dch.CollectorId = 2198 -- Для передачи
    where c.Status = 3
)

,assignsFin as 
(
    select
        debtorid
        ,assignId
        ,dense_rank() over (order by rn % (select count(*) from u)) as nextCollectorId
    from assigns
)

select
    a.*
    ,u.userid
--into #collectorAssigns
from assignsFin a
inner join u on u.rn = a.nextCollectorId

/

--update dch
--    set dch.islatest = 0
select dch.*
from #collectorAssigns ca
inner join dbo.DebtorCollectorHistory dch on dch.id = ca.assignid

--insert into dbo.DebtorCollectorHistory 
select
    ca.debtorid
    ,ca.userid
    ,1
    ,getdate()
    ,2332
from #collectorAssigns ca

/
select
    fu.Id as clientid
    ,c.id as creditid
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,u.username as collector
from #collectorAssigns ca
inner join dbo.Debtors d on d.id = ca.debtorid
inner join dbo.Credits c on c.Id = d.creditid
inner join dbo.FrontendUsers fu on fu.Id = c.userid
inner join dbo.syn_CmsUsers u on u.userid = ca.userid