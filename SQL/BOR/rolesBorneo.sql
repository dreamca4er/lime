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
        select '�eadCollector' as newRoleName union
        select '�eadVerificator' as newRoleName union
        select 'admin'
    ) a on substring(reverse(ar.Name), 1, len(ar.Name) - 1) = substring(reverse(a.newRoleName), 1, len(a.newRoleName) - 1)
        or ar.name = N'������� ��������' and a.newRoleName = 'SeniorOperator'
        or ar.name = N'������� ���������' and a.newRoleName = 'ExternalCollector'
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
    where su.username not in ( N'��� ������ �������������', N'Ivan Ivanov')
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
    select N'("������: ��")' as rightName, 1 as rightTypeId union
    select N'("�������: ��")' as rightName, 2 as rightTypeId union
    select N'("Pages: ��")' as rightName, 3 as rightTypeId union
    select N'("CMF: ��")' as rightName, 4 as rightTypeId union
    select N'("Media: ��")' as rightName, 5 as rightTypeId union
    select N'("�������: ��")' as rightName, 6 as rightTypeId union
    select N'("�������: ������ ��������")' as rightName, 7 as rightTypeId union
    select N'("�������: ��������� ���")' as rightName, 8 as rightTypeId union
    select N'("�������: ��������� ������")' as rightName, 9 as rightTypeId union
    select N'("�������: �������")' as rightName, 10 as rightTypeId union
    select N'("�����������: ��")' as rightName, 11 as rightTypeId union
    select N'("�����������: ������ ��������")' as rightName, 12 as rightTypeId union
    select N'("�����������: ������������� ����������")' as rightName, 13 as rightTypeId union
    select N'("�����������: ������")' as rightName, 14 as rightTypeId union
    select N'("�����������: �������")' as rightName, 15 as rightTypeId union
    select N'("�����������: ��������� ������")' as rightName, 16 as rightTypeId union
    select N'("�����������: ��������� SMS")' as rightName, 17 as rightTypeId union
    select N'("����������: ��")' as rightName, 18 as rightTypeId union
    select N'("����������: ������ ��������")' as rightName, 19 as rightTypeId union
    select N'("����������: �������� ��������")' as rightName, 20 as rightTypeId union
    select N'("����������: ����� �����������")' as rightName, 21 as rightTypeId union
    select N'("������: ��")' as rightName, 22 as rightTypeId union
    select N'("������: ��������������")' as rightName, 23 as rightTypeId union
    select N'("������: ����")' as rightName, 24 as rightTypeId union
    select N'("������: ����������")' as rightName, 25 as rightTypeId union
    select N'("������: ����������������")' as rightName, 26 as rightTypeId union
    select N'("������: ������������")' as rightName, 27 as rightTypeId union
    select N'("������: ����������")' as rightName, 28 as rightTypeId union
    select N'("������: �����������")' as rightName, 29 as rightTypeId union
    select N'("������: �� ��")' as rightName, 30 as rightTypeId union
    select N'("���������: ��")' as rightName, 31 as rightTypeId union
    select N'("���������: blacklist")' as rightName, 32 as rightTypeId union
    select N'("���������: ������")' as rightName, 33 as rightTypeId union
    select N'("���������: �������")' as rightName, 34 as rightTypeId union
    select N'("���������: ������")' as rightName, 35 as rightTypeId union
    select N'("���������: ����")' as rightName, 36 as rightTypeId union
    select N'("���������: ����������")' as rightName, 37 as rightTypeId union
    select N'("���������: ��������� �����������")' as rightName, 38 as rightTypeId union
    select N'("���������: ���������� ������� ����� / ��������")' as rightName, 39 as rightTypeId union
    select N'("���������: ����������������")' as rightName, 40 as rightTypeId union
    select N'("Users: ��")' as rightName, 41 as rightTypeId union
    select N'("Users: ������ �������������")' as rightName, 42 as rightTypeId union
    select N'("Users: ����")' as rightName, 43 as rightTypeId union
    select N'("���������: ����������")' as rightName, 44 as rightTypeId union
    select N'("������: ��")' as rightName, 45 as rightTypeId union
    select N'("�����������: ��������� �����������")DebtorsExtend', 46 union
    select N'("�������: ����������������� ��������")' as rightName, 47 as rightTypeId union
    select N'("���������: �������")' as rightName, 48 as rightTypeId union
    select N'("�������: �������� ������")' as rightName, 49 as rightTypeId union
    select N'("�������: ������")' as rightName, 50 as rightTypeId union
    select N'("�������: �������� ����������")' as rightName, 51 as rightTypeId union
    select N'("�������: ������������ ����")' as rightName, 52 as rightTypeId union
    select N'("�������: ����������������")' as rightName, 53 as rightTypeId union
    select N'("�������: �����������")' as rightName, 54 as rightTypeId union
    select N'("�������: �����������")' as rightName, 55 as rightTypeId union
    select N'("�������: ����������� ������")' as rightName, 56 as rightTypeId union
    select N'("�����������: ��������������")' as rightName, 57 as rightTypeId union
    select N'("�����������: ��������� �������� ������")' as rightName, 58 as rightTypeId union
    select N'("�������: ������� ������")' as rightName, 59 as rightTypeId union
    select N'("�����������: ������������� ������ 1")' as rightName, 60 as rightTypeId union
    select N'("�����������: ������������� ������ 2")' as rightName, 61 as rightTypeId union
    select N'("�����������: ������������� ������ 3")' as rightName, 62 as rightTypeId union
    select N'("�����������: ������������� ������ 4")' as rightName, 63 as rightTypeId union
    select N'("�����������: ������������� ������� ���������")' as rightName, 64 as rightTypeId union
    select N'("�����������: ������������� �������� ���������")' as rightName, 65 as rightTypeId union
    select N'("�������: �������� ����� ��������")' as rightName, 66 as rightTypeId union
    select N'("�������: ���������� ��������")' as rightName, 67 as rightTypeId union
    select N'("�������: ���������� �������")' as rightName, 68 as rightTypeId union
    select N'("�����������: ������ �������������")' as rightName, 69 as rightTypeId union
    select N'("�������: ��������� Cronos-������")' as rightName, 70 as rightTypeId
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

