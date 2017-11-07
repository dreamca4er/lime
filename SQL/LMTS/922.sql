select
    ca.userid
    ,ca.creditid
    ,u.username
    ,ar.Name as role
from dbo.tf_getcollectorassigns(getdate(), getdate(), 0) ca
inner join dbo.syn_CmsUsers u on u.userid = ca.collectorid
inner join dbo.AclAdminRoles aar on aar.AdminId = ca.collectorid
left join dbo.AclRoles ar on ar.Id = aar.AclRoleId
    and ar.Name like 'collector%'
where datediff(d, ca.overdueStart, getdate()) + 1 = 70
    and ca.collectorAssignEnd is null

