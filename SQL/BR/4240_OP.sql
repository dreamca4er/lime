set transaction isolation level read uncommitted
;

drop table if exists #ClientInfo
;

select
    uth.DateCreated as TariffDate
    ,ts.StepName
    ,ts.StepMaxAmount
    ,uc.UserId
    ,fu.DateRegistred
    ,uc.Passport
    ,fu.MobilePhone
    ,uc.AdditionalPhone
    ,uc.OrganizationName
    ,uai.RegRegion
    ,c.*
into #ClientInfo
from dbo.UserTariffHistory uth
inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId 
inner join dbo.UserCards uc on uc.UserId = uth.UserId
inner join dbo.FrontendUsers fu on fu.id = uth.UserId
left join dbo.UserAddresses ua on ua.id = uc.RegAddressId
left join dbo.vw_KladrStreets ks on ks.StreetId = ua.StreetId
left join dbo.UserAdminInformation uai on uai.UserId = uth.UserId
outer apply
(
    select
        c.id as CreditId
        ,pw.Description as MoneyWay
        ,cs.Description as CreditStatus
        ,p.CardNumber
        ,c.DateStarted
        ,dateadd(d, c.Period, c.DateStarted) as ContractDate
        ,c.Amount
    from dbo.credits c
    inner join dbo.Payments p on p.id = c.BorrowPaymentId
    inner join dbo.EnumDescriptions pw on pw.Value = c.Way
        and pw.Name = 'MoneyWay'
    inner join dbo.EnumDescriptions cs on cs.Value = c.Status
        and cs.Name = 'CreditStatus'
    where c.UserId = uth.UserId
        and c.TariffId = ts.TariffID
        and c.DateCreated > uth.DateCreated
        and not exists 
            (
                select 1 from dbo.UserTariffHistory uth2
                inner join dbo.vw_TariffSteps ts2 on ts2.StepID = uth2.StepId
                where uth2.UserId = uth.UserId
                    and ts2.TariffID = ts.TariffID
                    and uth2.DateCreated < uth.DateCreated
            )
) c
where uth.CreatedByUserId = 4535 --Конга: 4535; Манго: 1464
    and uth.DateCreated >= '20180929'
;

drop table if exists #LimePassport
;

select Number as Passport
into #LimePassport
from "BOR-LIME".Borneo.client."Identity" c
where c.Number in (select Passport collate Cyrillic_General_CI_AS from #ClientInfo)
;

drop table if exists #LimePhone
;

select right(PhoneNumber, 10) as Phone
into #LimePhone
from "BOR-LIME".Borneo.client.vw_client c
where right(PhoneNumber, 10) in (select right(MobilePhone, 10) collate Cyrillic_General_CI_AS from #ClientInfo)
;

drop table if exists #LimeAdditionalPhone
;

select right(PhoneNumber, 10) as AdditionalPhone
into #LimeAdditionalPhone
from "BOR-LIME".Borneo.client.Phone c
where right(PhoneNumber, 10) in (select right(AdditionalPhone, 10) collate Cyrillic_General_CI_AS from #ClientInfo)
    and Phonetype = 5
;

drop table if exists #MangoAdditionalPhone
;

select right(uc.AdditionalPhone, 10) as AdditionalPhone
into #MangoAdditionalPhone
from "Mango-DB".Limezaim_Website.dbo.UserCards uc
where right(uc.AdditionalPhone, 10) in (select right(AdditionalPhone, 10) collate Cyrillic_General_CI_AS from #ClientInfo)
;

drop table if exists #MangoPassport
;

select uc.Passport
into #MangoPassport
from "Mango-DB".Limezaim_Website.dbo.UserCards uc
where uc.Passport in (select Passport collate Cyrillic_General_CI_AS from #ClientInfo)
;

drop table if exists #MangoPhone
;

select right(fu.MobilePhone, 10) as Phone
into #MangoPhone
from "Mango-DB".Limezaim_Website.dbo.FrontendUsers fu
where right(fu.MobilePhone, 10) in (select right(MobilePhone, 10) collate Cyrillic_General_CI_AS from #ClientInfo)
;
/

select
    UserId
    ,DateRegistred
    ,Passport
    ,MobilePhone
    ,AdditionalPhone
    ,RegRegion
    ,OrganizationName
    ,TariffDate
    ,StepName
    ,StepMaxAmount
    ,CreditId
    ,Amount
    ,MoneyWay
    ,CardNumber
    ,DateStarted
    ,ContractDate
    ,CreditStatus
    ,LimePassportDouble
    ,LimePhoneDouble
    ,MangoPassportDouble
    ,MangoPhoneDouble
from #ClientInfo ci
outer apply
(
    select top 1 1 as LimePassportDouble
    from #LimePassport cp
    where cp.Passport = ci.Passport collate Cyrillic_General_CI_AS
) LimePassport
outer apply
(
    select top 1 1 as LimePhoneDouble
    from #LimePhone lp
    where lp.Phone = ci.MobilePhone collate Cyrillic_General_CI_AS
) LimePhone
outer apply
(
    select top 1 1 as LimeAdditionalPhoneDouble
    from #LimeAdditionalPhone lp
    where lp.AdditionalPhone = ci.AdditionalPhone collate Cyrillic_General_CI_AS
) LimeAdditionalPhone

outer apply
(
    select top 1 1 as MangoPassportDouble
    from #MangoPassport cp
    where cp.Passport = ci.Passport collate Cyrillic_General_CI_AS
) MangoPassport
outer apply
(
    select top 1 1 as MangoPhoneDouble
    from #MangoPhone lp
    where lp.Phone = ci.MobilePhone collate Cyrillic_General_CI_AS
) MangoPhone
outer apply
(
    select top 1 1 as MangoAdditionalPhoneDouble
    from #MangoAdditionalPhone lp
    where lp.AdditionalPhone = ci.AdditionalPhone collate Cyrillic_General_CI_AS
) MangoAdditionalPhone