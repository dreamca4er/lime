with u as 
(
    select
        mu.UserId as MangoUserId
        ,mu.UserName as MangoUserName
        ,mu.Loginname as Loginname
        ,a.Username
        ,case
            when a.Is_Enabled = 'False' then N'Уволен на Лайм'
            when a.Username is not null then N'Есть на Лайме'
            when a.Username is null and a2.username is not null then N'Есть на Лайме, другой логин'
            else N'Нет на Лайме'
        end LimeStatus
        ,a2.username as OtherLimeLogin
        ,replace(replace(r.Roles, '{"Name":"', ''), '"}', '') as MangoRoles
    from "MANGO-DB".CmsContent_LimeZaim.dbo.Users mu
    left join sts.vw_admins a on a.Username = mu.loginname
    left join sts.vw_admins a2 on a2.Name = mu.UserName
        and a2.username != mu.loginname
    outer apply
    (
        select ar.Name
        from "MANGO-DB".LimeZaim_Website.dbo.AclAdminRoles aar
        inner join "MANGO-DB".LimeZaim_Website.dbo.AclRoles ar on ar.Id = aar.AclRoleId
        where aar.AdminId = mu.userid
            and ar.IsEnabled = 1
        order by ar.Name
        for json auto, without_array_wrapper
    ) as r(Roles)
    where mu.IsEnabled = 1
        and mu.UserId not in (1353, 1368, 1369, 1361, 1193, 1244, 1264, 1263, 1307, 1000, 1250)
)

,col as 
(
    select
        *
        ,case MangoRoles
            when 'Collector1,Collector2'
            then N'Коллектор ОДВ'
            when 'Collector3'
            then N'Коллектор ГТС'
        end as LimeRole
    from u
    where MangoRoles like '%Collector[123]%'
)

select *
from u
where MangoRoles not like '%Collector[123]%'

select *
from sts.vw_rc