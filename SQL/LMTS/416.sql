select
    c.UserId as "id �������"
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as "���"
    ,isnull(ua.CityName, '') 
    + isnull(', ' + ua.StreetName, '') 
    + lower(isnull(N', �. ' + ua.House, ''))
    + lower(isnull(N', �. ' + ua.Block, ''))
    + lower(isnull(N', ��. ' + ua.Flat, '')) as "����� �����������"
    ,isnull(ua.CityName, '') as "����� �����������"
	,isnull(kh."index", ks."index") as "������ �����������"
    ,left(uc.Passport, 4) as "����� ��������"
    ,right(uc.Passport, 6) as "����� ��������"
    ,format(uc.PassportIssuedOn, 'dd.MM.yyyy') as "���� ������ ��������"
    ,uc.PassportIssuedBy as "��� ����� �������"
    ,c.DogovorNumber as "����� ��������"
    ,format(c.DateCreated, 'dd.MM.yyyy') as "���� ��������"
    ,cb.Amount
    + cb.PercentAmount 
    + cb.CommisionAmount 
    + cb.PenaltyAmount 
    + cb.LongPrice 
    + cb.TransactionCosts as "������ �����������"
    ,cb.Amount as "������������ ������������� �� ��������� �����"
    ,cb.PercentAmount as "������������ ������������� �� ���������"
    ,cb.PenaltyAmount as "������������� �� �������"
    ,cb.LongPrice as "������������ ����������� �� ����������"
    ,cb.TransactionCosts as "������������ ������������� �� ������ �������������� ��������"
from dbo.Credits c
inner join dbo.UserAdminInformation uai on uai.UserId = c.UserId
    and datediff(d, uai.LastCreditDatePay, getdate()) >= 60 
    and datediff(d, uai.LastCreditDatePay, getdate()) <=
        case 
            when (
                    select t.Name
                    from dbo.Tariffs t
                    where t.id = 2
                  ) = 'Lime'
             then 360
             else datediff(d, uai.LastCreditDatePay, getdate())
        end
inner join dbo.UserCards uc on uc.UserId = c.UserId
inner join dbo.FrontendUsers fu on fu.Id = c.userid
left join dbo.UserAddresses ua on ua.Id = uc.RegAddressId
left join dbo.locations street on street.id = ua.streetid
left join dbo.locations house on  house.id = ua.houseid
left join kladrhouses kh  on kh.code = house.kladrcode
left join kladrstreets ks on ks.code = street.kladrcode
outer apply
(
    select top 1
        cb.Amount
        ,cb.PercentAmount
        ,cb.CommisionAmount
        ,cb.PenaltyAmount
        ,cb.LongPrice
        ,cb.TransactionCosts
    from dbo.CreditBalances cb
    where cb.CreditId = c.id
    order by cb.Date desc
) cb
where uc.IsFraud = 0
    and c.Status = 3
    and not exists (
                    select 1 from dbo.DebtorCollectorHistory dch
                    inner join dbo.Debtors d on d.Id = dch.DebtorId
                    where d.CreditId = c.id
                        and dch.IsLatest = 1
                        and (
                            (
                                select t.Name
                                from dbo.Tariffs t
                                where t.id = 2
                             ) = 'Lime'
                             and dch.CollectorId in (1163, 1195, 1239 ,1263 ,1264 -- �����
                                                    ,1229 -- ��� �������� � ���
                                                    ,1049 -- �������
                                                    ,1237 -- �� ��������
                                                     )
                             or (
                                    select t.Name
                                    from dbo.Tariffs t
                                    where t.id = 2
                                  ) = 'Konga'
                             and dch.CollectorId in (1049 -- �������
                                                    ,2234 -- �� ��������
                                                    )
                             )
                    )
    and not exists (
                    select 1 from dbo.DebtorTransferCession dtc
                    inner join dbo.Debtors d on d.id = dtc.DebtorId
                    where d.CreditId = c.Id
                    )

