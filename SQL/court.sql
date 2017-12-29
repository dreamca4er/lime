select
    fu.id as "ID"
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as "���"
    ,'' as "������ ��������"
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as "�������������� ��������"
    ,c.DogovorNumber as "����� �������� �����"
    ,c.DateCreated as "���� �������� �����"
    ,edu.Description as "����� ������ �����"
    ,fu.MobilePhone as "��������� �������"
    ,c.DatePaid  as "���� ������� �����"
    ,''as "�������� ���������, ����"
    ,c.Amount as "����� ����� �� ��������"
    ,cb.Amount - isnull(cp.Amount, 0) as "������� ���� �����"
    ,c.Period as "���� �����, ����"
    ,cb.PercentAmount - isnull(cb.PercentAmount, 0) as "�������� (���)"
    ,cb.PenaltyAmount - isnull(cb.PenaltyAmount, 0) as "����� (���)"
    ,us.State as "������ �������"
    ,ua.CityName + isnull(', ' + ua.StreetName, '') 
     + N', �. ' + ua.House 
     + isnull(N', �. ' + ua.Block, '')
     + isnull(N', ��. ' + ua.Flat, '') as "����� �����������"
    ,uaf.CityName + isnull(' ' + uaf.StreetName, '') 
     + N', �. ' + uaf.House 
     + isnull(N', �. ' + uaf.Block, '')
     + isnull(N', ��. ' + uaf.Flat, '') as "����� ������������ ����� ����������"
    ,uc.Passport as "����� ����� (�� ��������)"
    ,uc.PassportIssuedOn as "���� ������ (�� ��������)"
    ,uc.PassportIssuedBy as "��� ����� (�� ��������)"
    ,uc.Birthday as "���� �������� ��������"
    ,uc.BirthPlace as "����� ��������"
    ,uc.Gender as "���"
    ,datediff(d, fu.Birthday, getdate()) / 365 as "������� �������"
    ,'' as "������� ������ ��������"
    ,uc.OrganizationName as "����� ������"
    ,'' as "����� ������(�����)"
    ,uc.Position as "���������"
    ,uc.Income as "����������� �����"
    ,uc.IsCourtOrder as "������� �������� ������"
    ,uc.IsDied as "������� ����"
    ,fu.BankruptType as "���� �����������"
from dbo.FrontendUsers fu with (nolock)
inner join dbo._court l with (nolock) on l.id = fu.id
inner join dbo.Credits c with (nolock) on c.DogovorNumber = l.contractNumber
    and c.Status != 8
inner join dbo.EnumDescriptions edu with (nolock) on edu.Value = c.Way
    and edu.Name = 'MoneyWay'
inner join dbo.vw_UserStatuses us with (nolock) on us.Id = fu.id
inner join dbo.UserCards uc with (nolock) on uc.UserId = fu.id
inner join dbo.UserAddresses ua with (nolock) on ua.Id = uc.RegAddressId
left join dbo.UserAddresses uaf with (nolock) on uaf.Id = uc.FactAddressId
outer apply
(
    select top 1 
        Amount
        ,PercentAmount
        ,PenaltyAmount
    from dbo.CreditBalances cb  with (nolock)
    where cb.CreditId = c.id
    order by cb.Date desc
) as cb
outer apply
(
    select 1
        Amount
        ,PercentAmount
        ,PenaltyAmount
    from dbo.CreditPayments cp with (nolock)
    where cp.CreditId = c.id
        and cp.DateCreated >= cast(getdate() as date)
) as cp
