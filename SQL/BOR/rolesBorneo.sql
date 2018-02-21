with roles as 
(
    select
        ar.Id as roleId
        ,ar.name
        ,newRoleName
    from AclRoles ar
    full join
    (
        SELECT N'Accountant' AS newRoleName union all
        SELECT N'admin' AS newRoleName union all
        SELECT N'Administrations' AS newRoleName union all
        SELECT N'Collector' AS newRoleName union all
        SELECT N'HeadAccountant' AS newRoleName union all
        SELECT N'HeadCollector' AS newRoleName union all
        SELECT N'HeadMarketer' AS newRoleName union all
        SELECT N'HeadOperator' AS newRoleName union all
        SELECT N'HeadVerificator' AS newRoleName union all
        SELECT N'Lawyer' AS newRoleName union all
        SELECT N'Marketer' AS newRoleName union all
        SELECT N'OperatorFullAccess' AS newRoleName union all
        SELECT N'Operators' AS newRoleName union all
        SELECT N'PODFT' AS newRoleName union all
        SELECT N'RiskManager' AS newRoleName union all
        SELECT N'User' as newRoleName union all
        SELECT N'Verificators' AS newRoleName
    ) a on substring(reverse(ar.Name), 1, len(ar.Name) - 1) = substring(reverse(a.newRoleName), 1, len(a.newRoleName) - 1)
        or ar.name = N'Старший оператор' and a.newRoleName = 'HeadOperator'
        or ar.name = N'Внешний коллектор' and a.newRoleName = 'ExternalCollector'
        or ar.name in ('Collector1', 'Collector2', 'Collector3', 'Collector4', 'CollectorFullAccess') and a.newRoleName = 'Collector'
        or ar.name in ('Administration access', 'Developers') and a.newRoleName = 'admin'
        or ar.name like '%ReportsAccess' and a.newRoleName = 'User'
)

,excludeusers as 
(
    select name
    from (values ('lime'), ('nefedov'), ('o.bobkova'), ('stas1'), ('LudmilaB')
            ,('i.madisson'), ('i.markova'), ('n.sukhanov'), ('a.kozyaev'), ('s.samosenko'), ('k.zhilcov'), ('d.golubev')
            ,('e.frolova'), ('e.malinovskaya'), ('IvanS'), ('m.andronov'), ('n.ryzhenkov'), ('y.patrikeev'), ('y.popova'), ('i.sazonov'), ('y.dergunov')
            ,('e.zorkina')
            ,('k.raenok')
            ,('a.savchuk'), ('a.bibikov'), ('a.bibikova'), ('a.bikseitova')
            ,('d.nikolaeva')
            ,('e.tropina')
            ,('l.gabidullina')
            ,('t.ilyina')
            ,('AlinaK')
    ) as a(name)
            
)

,c as 
(
    select
        su.username
        ,su.LoginName
        ,su.userid as adminid
        ,r.newRoleName
        ,aar.AclRoleId
        ,su.UserEmail
    from syn_CmsUsers su 
    inner join AclAdminRoles aar on su.userid = aar.adminid
    left join roles r on r.roleid = aar.AclRoleId and su.loginname not in (select name from excludeusers)
        or (su.loginname in ('lime', 'nefedov', 'o.bobkova', 'stas1', 'LudmilaB') and r.newRoleName = 'admin')
        or (su.loginname in ('e.frolova', 'e.malinovskaya', 'IvanS', 'm.andronov', 'n.ryzhenkov', 'y.patrikeev', 'y.popova', 'i.sazonov', 'y.dergunov') and r.newRoleName = 'Lawyer')
        or (su.loginname = 'e.zorkina' and r.newrolename = 'HeadAccountant')
        or (su.loginname = 'k.raenok' and r.newrolename = 'HeadVerificator')
        or (su.loginname in ('a.savchuk', 'a.bibikov', 'a.bibikova', 'a.bikseitova') and r.newrolename = 'OperatorFullAccess')
        or (su.loginname = 'd.nikolaeva' and r.newrolename = 'Accountant')
        or (su.loginname = 'e.tropina' and r.newrolename = 'Verificators')
        or (su.loginname in ('i.madisson', 'i.markova', 'n.sukhanov', 'a.kozyaev', 's.samosenko', 'k.zhilcov', 'd.golubev') and r.newRoleName = 'HeadCollector')
        or (su.loginname = 'l.gabidullina' and r.newrolename = 'OperatorFullAccess')
        or (su.loginname = 't.ilyina' and r.newrolename = 'Operators')
        or (su.loginname = 'AlinaK' and r.newrolename = 'User')
    where su.username not in (N'Ivan Ivanov'
                            , N'Кредит Экспресс'
                            , N'Долгосрочные  займы'
                            , 'Vladimir Timkin'
                            , 'Pavel Kalinin'
                            , 'Konga1 Konga1'
                            , N'КА ЭВЕРЕСТ 2'
                            , N'не оформлял'
                            , N'ПРИМА КОЛЛЕКТ'
                            , N'Судебное Взыскание'
                            , N'Возврат Эверест'
                            , N'Прима Новый'
                            , N'Для передачи в суд')
        and su.IsEnabled = 1
        and su.loginname not in ('fakecollector', 'cession', 'sysadmin')
        and su.loginname not like '%bars%'
        and su.loginname not like '%test%'
        and su.username not like N'%коллектор%'
        and su.username not like N'%Verif%'
        and su.username not like N'%Верифик%'
        and su.username not like N'%оператор%'
        and su.username not like N'%должники%'
        and su.username not like N'пул %'
)

,userRole as 
(
    select distinct 
        c.username
        ,c.LoginName
        ,c.adminid
        ,c.newRoleName
        ,c.UserEmail
        ,count(case when c.newRoleName != 'User' then 1 end) over (partition by c.adminId) as cntNotUser
        ,count(case when c.newRoleName = 'Lawyer' then 1 end) over (partition by c.adminId) as cntLawyer
        ,count(case when ar.name = 'OperatorFullAccess' then 1 end) over (partition by c.adminId) as cntOpFull
        ,count(case when c.newRoleName = 'HeadVerificator' then 1 end) over (partition by c.adminId) as cntVerFull
        ,count(case when c.newRoleName = 'HeadCollector' then 1 end) over (partition by c.adminId) as cntCollFull
        ,count(case when c.newRoleName = 'Collector' then 1 end) over (partition by c.adminId) as cntColl
        ,count(case when c.newRoleName = 'admin' then 1 end) over (partition by c.adminId) as cntAdmin
        ,count(case when c.newRoleName = 'Accountant' then 1 end) over (partition by c.adminId) as cntAcc
        ,concat('{', '"hash":"', up.passwordhash, '","version":"admin"}') as passwordhash
        ,ar.name as oldRoleName
    from c
    left join AclRoles ar on ar.Id = c.AclRoleId
    outer apply
    (
        select top 1 up.PasswordHash, up.PasswordSalt
        from CmsContent_LimeZaim.dbo.UserPasswords up
        where up.userid = c.adminid
        order by DateCreated desc
    ) up
)

select distinct
     username
    ,LoginName
    ,adminid
    ,passwordhash
    ,oldRoleName
    ,UserEmail
    ,newrolename
    ,case
        when LoginName in ('n.sharikova', 'u.alhimova') then 0
        when newrolename = 'Collector' then 1
    end forDistribution
from userRole
where (cntNotUser = 0 and newRoleName = 'User' or newRoleName != 'User')
    and (cntLawyer > 0 and newRoleName = 'Lawyer' or cntLawyer = 0)
    and (cntOpFull > 0 and newRoleName != 'Operators' or cntOpFull = 0)
    and (cntVerFull > 0 and newRoleName != 'Verificators' or cntVerFull = 0)
    and (cntCollFull > 0 and newRoleName != 'Collector' or cntCollFull = 0)
    and (cntAcc > 0 and newRoleName = 'Accountant' or cntAcc = 0)
    and (cntColl > 0 and newRoleName = 'Collector' or cntColl = 0)
    or newRoleName is null

union

select N'Буффер Тех.просрочка', 'FakeCollectorTechnical', null, 'Collector', null, null, null, 0

union

select N'Буффер ПС', 'FakeCollectorPS', null, 'Collector', null, null, null, 0

union

select N'Буффер ОСВ', 'FakeCollectorOSV', null, 'Collector', null, null, null, 0