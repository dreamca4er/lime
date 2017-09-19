select top 75000
    fu.Firstname as "�������"
    ,fu.Fathername as "���"
    ,fu.Lastname as "��������"
    ,fu.MobilePhone as "�������"
    ,left(uc.Passport, 4) as "����� ��������"
    ,right(uc.Passport, 6) as "����� ��������"
    ,format(fu.Birthday, 'dd.MM.yyyy') as "���� ��������"
    ,format(u.date, 'dd.MM.yyyy') as "���� ������"
    ,u.target
    ,uai.RegRegion as "������ ������ ������"
from dbo._MegafonDs1 u
left join dbo.FrontendUsers fu on fu.Id = u.UserID
left join dbo.UserCards uc on uc.UserId = u.UserID
left join dbo.UserAdminInformation uai on uai.UserId = u.UserID
where u.is_lime = 1
    and uc.Passport is not null
order by u.UserID 
--offset 75000 rows 
--fetch next 30165 rows only