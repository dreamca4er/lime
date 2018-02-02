with roles as 
(
    select
        ar.Id as roleId
        ,ar.name
        ,newRoleName
    from AclRoles ar
    full join
    (
        select 'Administrations' as newRoleName union
        select 'client' as newRoleName union
        select 'CollectorDZP' as newRoleName union
        select 'CollectorFullAccess' as newRoleName union
        select 'CollectorGSSS' as newRoleName union
        select 'CollectorGTS' as newRoleName union
        select 'CollectorOV' as newRoleName union
        select 'CollectorPrimaryDispatch' as newRoleName union
        select 'CollectorReportsAccess' as newRoleName union
        select 'Developers' as newRoleName union
        select 'ExternalCollector' as newRoleName union
        select 'HeadMarketer' as newRoleName union
        select 'Lawyer' as newRoleName union
        select 'Marketer' as newRoleName union
        select 'OperatorFullAccess' as newRoleName union
        select 'Operators' as newRoleName union
        select 'passwordChanger' as newRoleName union
        select 'PODFT' as newRoleName union
        select 'RiskManager' as newRoleName union
        select 'SeniorOperator' as newRoleName union
        select 'Verificators' as newRoleName union
        select 'НeadCollector' as newRoleName union
        select 'НeadVerificator' as newRoleName union
        select 'admin'
    ) a on substring(reverse(ar.Name), 1, len(ar.Name) - 1) = substring(reverse(a.newRoleName), 1, len(a.newRoleName) - 1)
        or ar.name = N'Старший оператор' and a.newRoleName = 'SeniorOperator'
        or ar.name = N'Внешний коллектор' and a.newRoleName = 'ExternalCollector'
        or ar.name = 'Collector1' and a.newRoleName = 'CollectorOV'
        or ar.name = 'Collector2' and a.newRoleName = 'CollectorGSSS'
        or ar.name = 'Collector3' and a.newRoleName = 'CollectorGTS'
        or ar.name = 'Collector4' and a.newRoleName = 'CollectorDZP'
        or ar.id = 1 and a.newRoleName = 'admin'
)

,c as 
(
    select
        su.username
        ,aar.*
        ,r.newRoleName
    from AclAdminRoles aar
    inner join syn_CmsUsers su on su.userid = aar.adminid
    left join roles r on r.roleid = aar.AclRoleId
    where su.username not in ( N'Пул жертвы мошенничества', N'Ivan Ivanov')
)

select 
    c.*
    ,ar.name
from c
left join AclRoles ar on ar.Id = c.AclRoleId
where newRoleName is null
    and not exists 
                (
                    select 1 from c c1
                    where c.username = c1.username
                        and c1.newRoleName is not null
                )
--where aclroleid = 1
/
with rt as 
(
    select N'("Панель: всё")' as rightName, 1 as rightTypeId union
    select N'("Контент: всё")' as rightName, 2 as rightTypeId union
    select N'("Pages: всё")' as rightName, 3 as rightTypeId union
    select N'("CMF: всё")' as rightName, 4 as rightTypeId union
    select N'("Media: всё")' as rightName, 5 as rightTypeId union
    select N'("Клиенты: всё")' as rightName, 6 as rightTypeId union
    select N'("Клиенты: список клиентов")' as rightName, 7 as rightTypeId union
    select N'("Клиенты: отправить смс")' as rightName, 8 as rightTypeId union
    select N'("Клиенты: отправить письмо")' as rightName, 9 as rightTypeId union
    select N'("Клиенты: экспорт")' as rightName, 10 as rightTypeId union
    select N'("Просрочники: всё")' as rightName, 11 as rightTypeId union
    select N'("Просрочники: список клиентов")' as rightName, 12 as rightTypeId union
    select N'("Просрочники: переназначить коллектора")' as rightName, 13 as rightTypeId union
    select N'("Просрочники: отчёты")' as rightName, 14 as rightTypeId union
    select N'("Просрочники: экспорт")' as rightName, 15 as rightTypeId union
    select N'("Просрочники: отправить письмо")' as rightName, 16 as rightTypeId union
    select N'("Просрочники: отправить SMS")' as rightName, 17 as rightTypeId union
    select N'("Переданные: всё")' as rightName, 18 as rightTypeId union
    select N'("Переданные: список клиентов")' as rightName, 19 as rightTypeId union
    select N'("Переданные: передать клиентов")' as rightName, 20 as rightTypeId union
    select N'("Переданные: сброс автодозвона")' as rightName, 21 as rightTypeId union
    select N'("Отчёты: всё")' as rightName, 22 as rightTypeId union
    select N'("Отчёты: управленческие")' as rightName, 23 as rightTypeId union
    select N'("Отчёты: лиды")' as rightName, 24 as rightTypeId union
    select N'("Отчёты: коллекторы")' as rightName, 25 as rightTypeId union
    select N'("Отчёты: пользовательские")' as rightName, 26 as rightTypeId union
    select N'("Отчёты: верификаторы")' as rightName, 27 as rightTypeId union
    select N'("Отчёты: шифрование")' as rightName, 28 as rightTypeId union
    select N'("Отчёты: бухгалтерия")' as rightName, 29 as rightTypeId union
    select N'("Отчёты: ЦБ РФ")' as rightName, 30 as rightTypeId union
    select N'("Параметры: всё")' as rightName, 31 as rightTypeId union
    select N'("Параметры: blacklist")' as rightName, 32 as rightTypeId union
    select N'("Параметры: тарифы")' as rightName, 33 as rightTypeId union
    select N'("Параметры: регионы")' as rightName, 34 as rightTypeId union
    select N'("Параметры: купоны")' as rightName, 35 as rightTypeId union
    select N'("Параметры: суды")' as rightName, 36 as rightTypeId union
    select N'("Параметры: цессионеры")' as rightName, 37 as rightTypeId union
    select N'("Параметры: настройки автодозвона")' as rightName, 38 as rightTypeId union
    select N'("Параметры: блокировка каналов займа / возврата")' as rightName, 39 as rightTypeId union
    select N'("Параметры: реструктуризация")' as rightName, 40 as rightTypeId union
    select N'("Users: всё")' as rightName, 41 as rightTypeId union
    select N'("Users: список пользователей")' as rightName, 42 as rightTypeId union
    select N'("Users: роли")' as rightName, 43 as rightTypeId union
    select N'("Параметры: коллекторы")' as rightName, 44 as rightTypeId union
    select N'("Звонки: Всё")' as rightName, 45 as rightTypeId union
    select N'("Просрочники: начальник коллекторов")DebtorsExtend', 46 union
    select N'("Клиенты: автораспределение клиентов")' as rightName, 47 as rightTypeId union
    select N'("Параметры: Скоринг")' as rightName, 48 as rightTypeId union
    select N'("Клиенты: Продлить кредит")' as rightName, 49 as rightTypeId union
    select N'("Клиенты: Детали")' as rightName, 50 as rightTypeId union
    select N'("Клиенты: Загрузка Документов")' as rightName, 51 as rightTypeId union
    select N'("Клиенты: заголовочный блок")' as rightName, 52 as rightTypeId union
    select N'("Клиенты: Реструктуризация")' as rightName, 53 as rightTypeId union
    select N'("Клиенты: Уведомления")' as rightName, 54 as rightTypeId union
    select N'("Клиенты: Комментарии")' as rightName, 55 as rightTypeId union
    select N'("Клиенты: Блокировать выдачу")' as rightName, 56 as rightTypeId union
    select N'("Просрочники: Взаимодействие")' as rightName, 57 as rightTypeId union
    select N'("Просрочники: отправить бумажное письмо")' as rightName, 58 as rightTypeId union
    select N'("Клиенты: Списать кредит")' as rightName, 59 as rightTypeId union
    select N'("Просрочники: Распределение группа 1")' as rightName, 60 as rightTypeId union
    select N'("Просрочники: Распределение группа 2")' as rightName, 61 as rightTypeId union
    select N'("Просрочники: Распределение группа 3")' as rightName, 62 as rightTypeId union
    select N'("Просрочники: Распределение группа 4")' as rightName, 63 as rightTypeId union
    select N'("Просрочники: Распределение внешний коллектор")' as rightName, 64 as rightTypeId union
    select N'("Просрочники: Распределение фейковый коллектор")' as rightName, 65 as rightTypeId union
    select N'("Клиенты: Просмотр новых клиентов")' as rightName, 66 as rightTypeId union
    select N'("Клиенты: Добавление платежей")' as rightName, 67 as rightTypeId union
    select N'("Клиенты: Блокировка клиента")' as rightName, 68 as rightTypeId union
    select N'("Просрочники: Жертвы мошенничества")' as rightName, 69 as rightTypeId union
    select N'("Клиенты: отправить Cronos-запрос")' as rightName, 70 as rightTypeId
)

select
    aro.Id
    ,aro.Name
    ,ari.RightType
    ,rt.rightName
from AclRoles aro
inner join AclAccessMatrix aam on aam.AclRoleId = aro.Id
inner join AclRights ari on ari.Id = aam.AclRightId
left join rt on rt.rightTypeId = ari.RightType
where aro.id in (13, 14, 15, 17, 18, 19, 21)

