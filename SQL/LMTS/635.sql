select
    ul.userid as "id �������"
    ,ul.lastname as "�������"
    ,ul.firstname as "���"
    ,ul.fathername as "��������"
    ,ul.mobilephone as "�������"
    ,ul.emailaddress as "Email"
    ,isnull(edu.Description, N'�� �����') as "������"
from dbo.UsersKonga ul
left join dbo.EnumDescriptions edu on edu.Value = ul.userStatus
    and edu.Name = 'UserStatusKind'
where ul.blockDate is null
    and ul.IsDied = 0
    and ul.IsFraud = 0
    and isnull(ul.userStatus, 0) not in (6, 12)
    and left(ul.mobilephone, 1) = '9'
/

select
    ul.userid as "id �������"
    ,ul.lastname as "�������"
    ,ul.firstname as "���"
    ,ul.fathername as "��������"
    ,ul.mobilephone as "�������"
    ,ul.emailaddress as "Email"
    ,isnull(edu.Description, N'�� �����') as "������"
from dbo.UsersLime ul
left join dbo.EnumDescriptions edu on edu.Value = ul.userStatus
    and edu.Name = 'UserStatusKind'
where ul.blockDate is null
    and ul.IsDied = 0
    and ul.IsFraud = 0
    and isnull(ul.userStatus, 0) not in (6, 12)
    and not exists
                    (
                        select 1 from dbo.UsersKonga lime
                        where lime.Passport = ul.Passport
                            and (lime.blockDate is not null
                                    or lime.IsDied = 1
                                    or lime.userStatus = 12
                                    or lime.IsFraud =1
                                )
                    )
    and left(ul.mobilephone, 1) = '9'
/

select
    ul.userid as "id �������"
    ,ul.lastname as "�������"
    ,ul.firstname as "���"
    ,ul.fathername as "��������"
    ,ul.mobilephone as "�������"
    ,ul.emailaddress as "Email"
    ,isnull(edu.Description, N'�� �����') as "������"
from dbo.UsersMango ul
left join dbo.EnumDescriptions edu on edu.Value = ul.userStatus
    and edu.Name = 'UserStatusKind'
where ul.blockDate is null
    and ul.IsDied = 0
    and ul.IsFraud = 0
    and isnull(ul.userStatus, 0) not in (6, 12)
    and not exists
                    (
                        select 1 from dbo.UsersKonga lime
                        where lime.Passport = ul.Passport
                            and (lime.blockDate is not null
                                    or lime.IsDied = 1
                                    or lime.userStatus = 12
                                    or lime.IsFraud =1
                                )
                    )
    and left(ul.mobilephone, 1) = '9'
