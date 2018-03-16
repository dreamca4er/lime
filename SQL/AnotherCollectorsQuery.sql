select
    u.username as "���������"
    ,ca.UserId as "id �������"
    ,ca.CreditId as "id �������"
    ,ca.CollectorAssignStart as "���� ������������"
    ,datediff(d, ca.OverdueStart, ca.CollectorAssignStart) + 1 as "���� ��������� �� ���� ������������"
    ,ca.CollectorAssignEnd as "���� �����������"
    ,datediff(d, ca.OverdueStart, isnull(ca.CollectorAssignEnd, getdate())) + 1 as "���� ��������� �� ���� ����������� (��� �� ������� ����, ���� ������ ����������)"
    ,ca.Amount as "������� �� ���� �����"
    ,ca.PercentAmount + ca.CommissionAmount + ca.PenaltyAmount as "������� �� ���������, ��������� � �������"
    ,ca.LongPrice as "����� �� ���������"
    ,ca.TransactionCosts as "�����. ��������"
    ,ld.LastPaymentDate as "���� ���������� ������� �� ������ ������ ���������� � ���������"
    ,case 
        when c.TariffId = 4
        then N'��'
        else N'��'
    end as "��� �����"
    ,cs.Description as "������ �����"
from dbo.tf_getCollectorAssigns('20180201', '20180228', 0) ca
inner join dbo.Credits c on c.id = ca.CreditId
inner join dbo.EnumDescriptions cs on cs.Value = c.Status
    and cs.Name = 'CreditStatus'
inner join syn_CmsUsers u on u.userid = ca.CollectorId
outer apply
(
    select max(DateCreated) as LastPaymentDate
    from dbo.CreditPayments cp
    where cp.CreditId = c.id
        and cp.DateCreated between ca.CollectorAssignStart and ca.CollectorAssignEnd
) as ld
