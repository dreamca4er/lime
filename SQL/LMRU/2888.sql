declare @root varchar(100) = 'xmlns="http://schemas.datacontract.org/2004/07/Fuse8.Websites.LimeZaim.Domain"';

with neededUsers as 
(
    select distinct c.UserId
    from dbo.Credits c
    where c.DateCreated >= dateadd(d, -30, getdate())
        and c.status != 8
        and cast(right(c.DogovorNumber, 3) as int) = 2
)

/*
with neededUsers as 
(
    select 355455 as UserId
)
*/
,creditInfo as 
(
    select
        c.UserId
        ,c.Amount
        ,c.DateCreated
        ,row_number() over (partition by c.userid order by c.id) as rn
        ,row_number() over (partition by c.userid order by c.Amount desc) as rnAmount
    from dbo.Credits c
    where c.UserId in (select UserId from neededUsers)
        and c.Status != 8
)

,firstCreditInfo as 
(
    select
        ci.userid
        ,ci.Amount
        ,ti.tariffName
    from creditInfo ci
    outer apply
    (
        select top 1
            concat(ts.TariffName, '\', ts.StepName) as tariffName
        from dbo.UserTariffHistory uth
        inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
        where uth.UserId = ci.userid
            and uth.DateCreated <= ci.DateCreated
        order by uth.Id desc
    ) ti
    where ci.rn = 1
)

,maxCreditInfo as 
(
    select
        ci.userid
        ,ci.Amount
        ,ti.tariffName
    from creditInfo ci
    outer apply
    (
        select top 1
            concat(ts.TariffName, '\', ts.StepName) as tariffName
        from dbo.UserTariffHistory uth
        inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
        where uth.UserId = ci.userid
            and uth.DateCreated <= ci.DateCreated
        order by uth.id desc
    ) ti
    where ci.rnAmount = 1
)

select
    fu.id as "������"
    ,datediff(yy, fu.Birthday, getdate()) as "�������"
    ,case
        when uc.Gender = 1 then N'�'
        when uc.Gender = 2 then N'�'
    end as "���"
    ,case 
        when cast(replace(AdditionalInfoSnapshot, @root, '') as xml).value('(UserAdditionalInfo[1]/MaritalStatus[1])', 'varchar(20)') = 'Unknown'
        then N'�� �����'
        when cast(replace(AdditionalInfoSnapshot, @root, '') as xml).value('(UserAdditionalInfo[1]/MaritalStatus[1])', 'varchar(20)') = 'Married'
        then N'������� � �����'
        when cast(replace(AdditionalInfoSnapshot, @root, '') as xml).value('(UserAdditionalInfo[1]/MaritalStatus[1])', 'varchar(20)') = 'NotMarried'
        then N'�� ������� � �����'
        when cast(replace(AdditionalInfoSnapshot, @root, '') as xml).value('(UserAdditionalInfo[1]/MaritalStatus[1])', 'varchar(20)') = 'CivilMarried'
        then N'����������� ����'
    end as "�������� ���������"
    ,case 
        when cast(replace(AdditionalInfoSnapshot, @root, '') as xml).value('(UserAdditionalInfo[1]/Children[1])', 'varchar(20)') = 'HasNot'
        then '0'
        when cast(replace(AdditionalInfoSnapshot, @root, '') as xml).value('(UserAdditionalInfo[1]/Children[1])', 'varchar(20)') = 'One'
        then '1'
        when cast(replace(AdditionalInfoSnapshot, @root, '') as xml).value('(UserAdditionalInfo[1]/Children[1])', 'varchar(20)') = 'Two'
        then '2'
        when cast(replace(AdditionalInfoSnapshot, @root, '') as xml).value('(UserAdditionalInfo[1]/Children[1])', 'varchar(20)') = 'Three'
        then '3'
        when cast(replace(AdditionalInfoSnapshot, @root, '') as xml).value('(UserAdditionalInfo[1]/Children[1])', 'varchar(20)') = 'Four'
        then '4+'
    end as "������� �����"
    ,cast(replace(AdditionalInfoSnapshot, @root, '') as xml).value('(UserAdditionalInfo[1]/Education[1])', 'varchar(20)') as "�����������"
    ,uc.Income as "�����"
    ,coalesce(uaf.CityName, uar.CityName) as "������ ����������"
    ,case 
        when uc.Resident = 1 then N'�������'
        when uc.Resident = 2 then N'��������� �� �����'
        when uc.Resident = 3 then N'��'
        when uc.Resident = 4 then N'���������'
        when uc.Resident = 5 then N'�������� �� ��������'
        when uc.Resident = 6 then N'��������� ������'
    end as "���������"
    ,uc.Position as "���������"
    ,substring(fu.EmailAddress, charindex('@', fu.EmailAddress) + 1, len(fu.EmailAddress)) as "Email �������"
    ,case 
        when cast(fu.DateRegistred as time) between cast('06:00' as time) and cast('11:59' as time)
        then N'����'
        when cast(fu.DateRegistred as time) between cast('12:00' as time) and cast('17:59' as time)
        then N'����'
        when cast(fu.DateRegistred as time) between cast('18:00' as time) and cast('23:59' as time)
            or cast(fu.DateRegistred as time) between cast('00:00' as time) and cast('05:59' as time)
        then N'�����/����'
    end as "����� ����� �����������"
    ,case 
        when datepart(dw, fu.DateRegistred) = 1 then N'��'
        when datepart(dw, fu.DateRegistred) = 2 then N'��'
        when datepart(dw, fu.DateRegistred) = 3 then N'��'
        when datepart(dw, fu.DateRegistred) = 4 then N'��'
        when datepart(dw, fu.DateRegistred) = 5 then N'��'
        when datepart(dw, fu.DateRegistred) = 6 then N'��'
        when datepart(dw, fu.DateRegistred) = 7 then N'��'
    end as "���� ������ �����������"
    ,fci.Amount as "������ ������� �����"
    ,fci.tariffName as "����� ������� �����"
    ,mci.Amount as "������ ������������ ����� �����"
    ,mci.tariffName as "������������ �����"
from dbo.FrontendUsers fu
inner join dbo.UserCards uc on uc.UserId = fu.id 
inner join firstCreditInfo fci on fci.userid = fu.id
inner join maxCreditInfo mci on mci.userid = fu.id
left join dbo.UserAddresses uaf on uaf.Id = uc.FactAddressId
left join dbo.UserAddresses uar on uar.Id = uc.RegAddressId