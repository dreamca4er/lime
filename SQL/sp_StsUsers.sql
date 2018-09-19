
ALTER PROCEDURE [bi].[sp_StsUsers](@UserList nvarchar(max) = null) as 

-- Если json со списком юзеров не был передан - генерируем его
if @UserList is null
begin
    with u as 
    (
        select
            u.Id as UserId
            ,(
                select 
                    u.Email
                    ,u.PasswordHash
                    ,u.UserName
                from (select 1) as a(b)
                for json auto, without_array_wrapper, include_null_values
            ) as UserAttributes
        from sts.Users u
        where u.username not like '[0-9]%'
    )
    
    ,uc as 
    (
        select distinct
            u.UserId
            ,(
                select 
                    uc.ClaimType
                    ,uc.ClaimValue
                from sts.UserClaims uc
                where uc.UserId = u.UserId
                for json path
            ) as Claims
        from u
    )
    
    ,ur as 
    (
        select distinct
            u.UserId
            ,replace(replace((
                select r.Name
                from sts.Roles r
                inner join sts.UserRoles ur on ur.RoleId = r.id
                where ur.UserId = u.UserId
                for json auto
            ), '{"Name":', ''), '}', '') as Roles
        from u
    )
    
    ,fin(UserAttributes) as 
    (
        select
            json_modify(json_modify(u.UserAttributes, '$.Claims', uc.Claims), '$.Roles', ur.Roles) as UserAttributes
        from u
        inner join uc on u.UserId = uc.UserId
        inner join ur on u.UserId = ur.UserId
        for json auto
    ) 
    
    select *
    from fin
end

-- Если передали json со списком юзеров и их свойствами - сравниваем и возвращем скрипты
else
begin
    drop table if exists #InputUsers
    ;
    
    drop table if exists #AddUsers
    ;
    
    drop table if exists #AddClaims
    ;
    
    drop table if exists #AddRoles
    ;
    
    drop table if exists #Changes
    ;
    
    create table #Changes
    (
        ChangeType nvarchar(50)
        ,q nvarchar(max)
    )
    ;
    
    declare @list table
    (
        j nvarchar(max)
    )
    ;
    
    insert @list
    select @UserList
    ;
    
    select t.*
    into #InputUsers
    from @list
    cross apply openjson(replace(replace(j, 'a.bondar', 'a.bondar11'), 'dolya', 'dol6ya'))
    with
        (
            UserName nvarchar(100) '$.UserAttributes.UserName'
            ,Email nvarchar(100) '$.UserAttributes.Email'
            ,PasswordHash nvarchar(100) '$.UserAttributes.PasswordHash'
            ,Claims nvarchar(max) '$.UserAttributes.Claims' as json
            ,Roles nvarchar(max) '$.UserAttributes.Roles'
        ) t
    ;
    
    --Все юзера
    select
        u.PasswordHash
        ,u.UserName
        ,u.Email
        ,isnull(su.id, newId()) as id
    into #AddUsers
    from #InputUsers u
    left join sts.users su on su.Username = u.Username
        and su.UserName not like '[0-9]%'
    ;
    
    -- Клэймы
    select
        au.id as UserId
        ,json_value(c.value, '$.ClaimType') as ClaimType
        ,json_value(c.value, '$.ClaimValue') as ClaimValue
    into #AddClaims
    from #InputUsers iu
    inner join #AddUsers au on au.UserName = iu.UserName
    cross apply openjson(iu.Claims) c
    ;
    
    -- Роли
    select
        au.id as UserId
        ,rl.id as RoleId
    into #AddRoles
    from #InputUsers iu
    inner join #AddUsers au on au.UserName = iu.UserName
    cross apply openjson(iu.Roles) r
    inner join sts.Roles rl on rl.Name = r.value
    ;
    
    with UsersToMerge as 
    (
        select
            PasswordHash,UserName,id,Email
        from #AddUsers
        
        except 
        
        select
            PasswordHash,UserName,id,Email
        from sts.Users u
    )
    
    insert #Changes
    select
        'Merge users' as ChangeType
        ,replace(replace(
        'Merge sts.Users as target
        using (values (''' 
            + cast(utm.id as nvarchar(36))
            + ''','
            + isnull('''' + utm.PasswordHash + '''', 'null')
            + ','
            + isnull('''' + utm.Email + '''', 'null')
            + ','''
            + utm.UserName
            + ''')) as source(id, PasswordHash, Email, UserName) 
            on target.id = source.id
        when matched then
            update set 
                PasswordHash = source.PasswordHash
                ,Email = source.Email
        when not matched then
            insert
            (
                EmailConfirmed,PasswordHash,PhoneNumberConfirmed,TwoFactorEnabled,LockoutEnabled,AccessFailedCount,UserName,id,IsEmployee,Email
            )
            values
            (
                1, source.PasswordHash, 1, 0, 0, 0, source.UserName, source.id, 1, source.Email
            )
        ;
        ', char(10), ' '), '    ', ' ')
    from UsersToMerge utm
    ;
    
    with ClaimsToMerge as 
    (
        select
            UserId,ClaimType,ClaimValue
        from #AddClaims
        
        except
        
        select
            uc.UserId,uc.ClaimType,uc.ClaimValue
        from sts.UserClaims uc
        inner join sts.users u on u.id = uc.userid
        where u.UserName not like '[0-9]%'
    )
    
    insert #Changes
    select 
        'Merge claims' as ChangeType
        ,replace(replace(
        'Merge sts.UserClaims as target
        using (values (''' 
            + cast(ctm.Userid as nvarchar(36))
            + ''','''
            + ctm.ClaimType
            + ''','
            + isnull('N''' + ctm.ClaimValue + '''', 'null')
            + ')) as source(UserId, ClaimType, ClaimValue)
            on target.UserId = source.UserId
                and target.ClaimType = source.ClaimType
        when matched then
            update set 
                ClaimValue = source.ClaimValue
        when not matched then
            insert
            (
                UserId,ClaimType,ClaimValue
            )
            values
            (
                source.UserId,source.ClaimType,source.ClaimValue
            )
        ;
        ', char(10), ' '), '    ', ' ')
    from ClaimsToMerge ctm
    ;
    
    with RolesToMerge as 
    (
        select UserId, RoleId from #AddRoles
        
        except 
        
        select ur.UserId, ur.RoleId 
        from sts.UserRoles ur
        inner join sts.users u on u.id = ur.userid
            and u.UserName not like '[0-9]%'
    )
    
    insert #Changes
    select 
        'Merge roles' as ChangeType
        ,replace(replace(
        'Merge sts.UserRoles as target
        using (values (''' 
            + cast(rtm.Userid as nvarchar(36))
            + ''','''
            + cast(rtm.RoleId as nvarchar(36))
            + ''')) as source(UserId, RoleId)
            on target.UserId = source.UserId
                and target.RoleId = source.RoleId
        when not matched then
            insert
            (
                UserId,RoleId
            )
            values
            (
                source.UserId,source.RoleId
            )
        ;
        ', char(10), ' '), '    ', ' ')
    from RolesToMerge rtm
    ;
    
    insert #Changes
    select 
        'Delete roles' as ChangeType
        ,'delete ur from sts.UserRoles ur where ur.UserId = ''' 
        + cast(ur.UserId as nvarchar(36))
        + ''' and ur.RoleId = '''
        + cast(ur.RoleId as nvarchar(36))
        + ''';'
    from sts.UserRoles ur
    inner join sts.users u on u.id = ur.userid
        and u.UserName not like '[0-9]%'
    where not exists
        (
            select 1 from #AddRoles ar
            where ur.Userid = ar.Userid
                and ur.RoleId = ar.RoleId
        )
    ;
    
    insert #Changes
    select 
        'Delete claims' as ChangeType
        ,'delete uc from sts.UserClaims uc where uc.UserId = '''
        + cast(uc.UserId as nvarchar(36))
        + ''' and uc.ClaimType = '''
        + uc.ClaimType
        + ''';'
    from sts.UserClaims uc
    inner join sts.users u on u.id = uc.userid
        and u.UserName not like '[0-9]%'
    where not exists 
        (
            select 1 from #AddClaims ac
            where uc.UserId = ac.UserId
                and uc.ClaimType =  ac.ClaimType
        )
    ;
    
    insert #Changes
    select 
        'Delete users' as ChangeType
        ,'delete u from sts.users u where u.id = '''
        + cast(u.id as nvarchar(36))
        + ''';'
    from sts.users u
    where not exists 
        (
            select 1 from #AddUsers au
            where au.Username = u.Username
        )
        and u.UserName not like '[0-9]%'
    ;
    
    select *
    from #Changes
    order by 
        case when ChangeType like 'Merge users' then 1 else 2 end
end
GO
