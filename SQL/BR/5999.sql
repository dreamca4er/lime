drop table if exists #c
;

select
    c.clientid
    , c.SNILS
    , c.BirthDate
    , c.PhoneNumber
    , c.Passport
    , c.IssuedOn
     ,c.UserBlockingPeriod
into #c
from client.UserStatusHistory ush
inner join client.vw_Client c on ush.ClientId = c.clientid
where ush.Status = 3
    and ush.IsLatest = 1
    and ush.CreatedOn >= '20180615'
    and c.IsFrauder = 0
    and c.IsDead = 0
    and c.DebtorProhibitInteractionType = 0
    and not exists 
        (
            select 1 from client.vw_Client c2
            where c2.Passport = c.Passport
                and c2.clientid != c.clientid
        )
;
/
drop table if exists #c2
;

select *
into #c2
from #c c
outer apply
(
    select top 1
        crr.CreatedOn as ScoreDate
        , crr.Score
    from cr.CreditRobotResult crr
    where crr.ClientId = c.clientid
        and crr.CreatedOn >= dateadd(d, -30, getdate())
        and crr.Score > 0
    order by crr.CreatedOn desc
) crr
where crr.Score >= 0.1
    or crr.Score is null
;

create index IX_c2_clientid_SNILS on #c2(clientid, SNILS)
;

drop table if exists #c3
;

select *
into #c3
from #c2 c
where not exists 
        (
            select 1 from client.Phone p
            where p.PhoneNumber = c.PhoneNumber
                and p.clientid != c.clientid
                and p.IsMain = 1
                and p.IsDeleted = 0
        )
/
drop table if exists #c4
;

select *
into #c4
from #c3 c
where year(c.BirthDate) < 2018 - 21
    and year(c.BirthDate) >= 2018 - 65
    and not exists 
        (
            select 1 from prd.vw_product p
            where p.ClientId = c.clientid
                and p.Status not in (1 ,5)
        )
/

drop table if exists #c5
;

select *
into #c5
from #c4 c
where not exists 
        (
            select 1 from client.Client c2
            where c2.SNILS = c.SNILS 
                and c2.id != c.clientid
                and c.SNILS is not null
                and c2.SNILS is not null
        )
    and exists 
        (
            select 1 from prd.vw_AllProducts ap
            where ap.ClientId = c.ClientId 
        )
/
drop table if exists #c6
;

select *
into #c6
from #c5 c
where not exists 
    (
        select 1 from cr.BlackListUser blu
        where blu.passports like '%' + c.passport + '%'
    )
/
drop table if exists ##c
;

select 
    c.*
    ,cl.Substatus
into ##c
from #c6 c
inner join client.Client cl on cl.id = c.Clientid
where not exists 
    (
        select 1  
        from cr.InvalidPassport ip
        where cast(left(c.Passport, 4) as int) = ip.Series
            and cast(right(c.Passport, 6) as int) = ip.Number
    )
    and cl.UserBlockingPeriod < 3600
    and cl.Substatus = 304
/
drop table if exists #eq
;

select
    lcp.ProjectClientId
    , pi.Type
    , pi.Lastname
    , pi.Firstname
    , pi.Farthername
    , pi.Gender
    , pi.Birthday
    , pi.BirthPlace
    , pi.Citizenship
    , pi.DocumentType
    , pi.DocumentNumber
    , pi.DocumentDate
    , pi.DocumentEndDate
    , pi.DocumentCountry
    , pi.DocumentPlace
    , pi.LastnameState
    , pi.FirstnameState
    , pi.FarthernameState
    , pi.GenderState
    , pi.BirthdayState
    , pi.BirthPlaceState
    , pi.CitizenshipState
    , pi.DocumentTypeState
    , pi.DocumentNumberState
    , pi.DocumentDateState
    , pi.DocumentEndDateState
    , pi.DocumentCountryState
    , pi.DocumentPlaceState
    , er.EquifaxRequestCreatedOn
into #eq
from cr.syn_EquifaxResponse er
inner join cr.syn_LocalClientProject lcp on lcp.LocalClientId = er.LocalClientId
inner join cr.syn_EquifaxPersonalInfo pi on pi.EquifaxResponseId = er.EquifaxResponseId
where lcp.ProjectClientId in (select ClientId from ##c)
    and lcp.Project = 1
    and pi.DocumentType = 1
;

create index IX_eq_ProjectClientId_EquifaxRequestCreatedOn on #eq(ProjectClientId, EquifaxRequestCreatedOn)
;

/
insert dbo.CustomListUsers
(
    CustomlistID,ClientId,DateCreated
)
select
    1102
    ,c.CLientId
    ,getdate()
from #eq eq
inner join client.vw_client c on c.clientid = eq.ProjectClientId
inner join ##c on ##c.clientid = c.clientid
where not exists
    (
        select 1 from #eq eq2
        where eq2.ProjectClientId = eq.ProjectClientId
            and eq2.EquifaxRequestCreatedOn > eq.EquifaxRequestCreatedOn
            and eq2.Type = 1
            
    )
    and Type = 1
    and eq.Birthday = c.BirthDate
    and c.Passport = eq.DocumentNumber
    and c.IssuedOn = eq.DocumentDate
    and ##c.Score is null
    and eq.EquifaxRequestCreatedOn > '20181126'

select
    c.clientid
    , isnull(c.Score, b.Score) as Score
from ##c c
left join dbo.br5999 b on b.UserID = c.clientid
where isnull(c.Score, b.Score) is null -->= 0.2
    
select *
from dbo.CustomList
where id = 1104

select  *
from dbo.CustomListUsers
where CustomlistID = 1104
/*
insert dbo.CustomListUsers
(
    CustomlistID,ClientId,DateCreated
)

select
    1104
    , c.clientid
    , getdate()
from ##c c
left join dbo.br5999 b on b.UserID = c.clientid
where isnull(c.Score, b.Score) is null -->= 0.2


select
    1104
    , c.clientid
    , isnull(c.Score, b.Score)
from ##c c
left join dbo.br5999 b on b.UserID = c.clientid
where isnull(c.Score, b.Score) is null


insert dbo.CustomListUsers
(
    CustomlistID,ClientId,DateCreated
)

select
    1105
    , c.clientid
    , getdate()
    , hasTariff
from ##c c
where score is not null
*/
/
select
    clu.ClientId
    , isnull(iif(t.TariffId >= 5, 5, TariffId), 4) as NewTariffId
into #t
from dbo.CustomListusers clu
inner join Client.Client c on c.id = clu.ClientId
    and c.Status = 3
    and c.UserBlockingPeriod < 3600
outer apply
(
    select top 1 
        th.TariffId
        , th.TariffName
    from client.vw_TariffHistory th
    where th.ClientId = clu.ClientId
        and th.ProductType = 1
    order by th.CreatedOn desc
) t
where clu.CustomlistID = 1105
/
select * -- update u set CustomField1 = t.NewTariffId
from #t t
inner join dbo.CustomListUsers u on u.ClientId = t.ClientId
    and u.CustomlistID = 1105

select * -- update th set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from dbo.CustomListUsers clu
inner join client.UserShortTermTariff th on th.ClientId = clu.ClientId
    and th.IsLatest = 1
where clu.CustomlistID = 1105

select * -- update th set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from dbo.CustomListUsers clu
inner join client.UserLongTermTariff th on th.ClientId = clu.ClientId
    and th.IsLatest = 1
where clu.CustomlistID = 1105
/

select * -- update c set Status = 2, Substatus = 203
from dbo.CustomListUsers clu
inner join Client.Client c on c.Id = clu.ClientId
where clu.CustomlistID = 1105
/

select * -- update ush set ush.IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from dbo.CustomListUsers clu
inner join client.UserStatusHistory ush on ush.ClientId = clu.ClientId
    and ush.IsLatest = 1
where clu.CustomlistID = 1105
/

--insert into client.UserShortTermTariff
--(
--    ClientId,TariffId,CreatedOn,CreatedBy,IsLatest
--)
select
    ClientId
    , CustomField1 as TariffId
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 1 as IsLatest
from dbo.CustomListUsers
where CustomlistID = 1105

/
--insert into client.UserStatusHistory
--(
--    ClientId,Status,IsLatest,CreatedOn,CreatedBy,BlockingPeriod,Substatus
--)
select
    ClientId
    , 2 as Status
    , 1 as IsLatest
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 0 as BlockingPeriod
    , 203 as Substatus
from dbo.CustomListUsers
where CustomlistID = 1105
/

select
    c.clientid
    , c.LastName
    , c.FirstName
    , c.FatherName
    , c.PhoneNumber
    , iif(c.EmailConfirmed = 1, c.Email, null) as Email
    , th.TariffName
    , th.MaxAmount
from dbo.CustomListUsers u
inner join client.vw_client c on c.clientid = u.ClientId
inner join client.vw_TariffHistory th on th.ClientId = u.ClientId
    and th.IsLatest = 1
where u.CustomlistID = 1105
/

select *
from dbo.CustomListUsers c
where CustomlistID = 1105
    and exists 
        (
            select 1 from prd.vw_product p
            where p.ClientId = c.ClientId
                and p.Status in (2, 3, 4, 7)
        )