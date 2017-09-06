select 
    case 
        when Way = -1 then 'Contact'
        when Way = -2 then N'�� ���������� ����'
        when Way = -3 then N'�� ���������� �����'
    end as "������"
    ,count(*) as "���-��"
    ,count(case when c.Amount >= 50000 then 1 end) as "������ 50 �.�."
    ,count(case when c.Amount < 50000 then 1 end) as "������ 50 �.�."
    ,avg(c.Amount) as "������� ���"
    ,min(c.Amount) as "����������� ����"
    ,max(c.Amount) as "������������ ����"
from dbo.Credits c
where TariffId = 4
    and status != 8
group by way