drop table if exists dbo.br1660DefaultList
;
drop table if exists #th
;

drop table if exists #Clients
;

select
    uth.UserId as ClientId
    ,case when ts.TariffId = 4 then 2 else 1 end as ProductType
    ,t.Name + '/' + ts.Name as TariffName
    ,cast(dateadd(d, ts.MaxPeriod, uth.DateCreated) as date) as TariffEndDate
    ,case 
        when cast(dateadd(d, ts.MaxPeriod, uth.DateCreated) as date) > cast(getdate() as date)
        then 1
        else 0
    end as IsLatest
into #th
from dbo.UserTariffHistory uth
inner join dbo.TariffSteps ts on ts.Id = uth.StepId
inner join dbo.Tariffs t on t.Id = ts.TariffId
where dateadd(d, ts.MaxPeriod, uth.DateCreated) >= dateadd(d, -45, getdate())
    and not exists 
        (
            select 1
            from dbo.UserTariffHistory uth2
            inner join dbo.TariffSteps ts2 on ts2.Id = uth2.StepId
                and ts2.TariffId = ts.TariffId
                and uth2.DateCreated > uth.DateCreated
                and uth2.userid = uth.userid
        )
;

select
    uc.UserId as ClientId
    ,uc.Passport
into dbo.br1660DefaultList
from dbo.UserCards uc
where exists
    (
        select 1 from #th
        where #th.ClientId = uc.UserId
    )
    and uc.IsFraud = 0
    and uc.IsDied = 0
    and uc.IsCourtOrder = 0
    and not exists 
        (
            select 1 from dbo.UserStatusHistory ush
            where ush.UserId = uc.UserId
                and ush.IsLatest = 1
                and ush.Status in (6, 12)
        )
    and not exists 
        (
            select 1 from dbo.Credits c
            where c.UserId = uc.userid
                and c.status not in (8, 2)
        )
;
-- select * from dbo.CustomList 40

--insert dbo.UserCustomLists
--(
--    CustomlistID, UserId
--)
--select 40, ClientId
--from dbo.br1660DefaultList
/
drop table if exists #OtherServ
;

drop table if exists #ClientStatus
;

drop table if exists #ProductStatus
;

drop table if exists dbo.br1660OtherSystemStatus
;

select *, cast('LIME' as nvarchar(20)) as ProductName
into #OtherServ
from "BOR-LIME".BORNEO.dbo.br1660DefaultList 
;

insert #OtherServ
select
    ClientId
    ,passport
    ,'MANGO' as ProductName
from "MANGO-DB".LimeZaim_Website.dbo.br1660DefaultList
;

create clustered index IX_OtherServ on #OtherServ(passport, productname)
;

select 
    os.*
    ,ed.Description as substatusName
into #ClientStatus
from #OtherServ os
inner join dbo.UserCards uc on uc.Passport = os.Passport collate SQL_Latin1_General_CP1_CI_AS
inner join dbo.UserStatusHistory ush on ush.UserId = uc.UserId
inner join dbo.EnumDescriptions ed on ed.Value = ush.Status
    and ed.Name = 'UserStatusKind'
where ush.IsLatest = 1
;

select 
    os.*
    ,ed.Description as StatusName
into #ProductStatus
from #OtherServ os
inner join dbo.UserCards uc on uc.Passport = os.Passport collate SQL_Latin1_General_CP1_CI_AS
inner join dbo.Credits c on uc.UserId = c.UserId
inner join dbo.EnumDescriptions ed on ed.Value = c.Status
    and ed.Name = 'CreditStatus'
where uc.Passport = os.Passport collate SQL_Latin1_General_CP1_CI_AS 
    and c.Status not in (5, 8)
    and not exists
        (
            select 1 from dbo.Credits c2
            where c2.UserId = c.UserId
                and c2.Status not in (5, 8)
                and c2.DateStarted > c.DateStarted
        )
;

select
    os.ClientId
    ,os.passport
    ,os.productname
    ,replace(replace(cs.ClientStatus, '{"substatusName":', ''), '}', '') as ClientStatus
    ,replace(replace(ps.ProductStatus, '{"StatusName":', ''), '}', '') as ProductStatus
into dbo.br1660OtherSystemStatus
from #OtherServ os
outer apply
(
    select distinct substatusName
    from #ClientStatus cs
    where cs.ClientId = os.ClientId
        and cs.ProductName = os.ProductName
    for json auto, without_array_wrapper
) cs(ClientStatus)
outer apply
(
    select StatusName
    from #ProductStatus ps
    where ps.ClientId = os.ClientId
        and ps.ProductName = os.ProductName
    for json auto, without_array_wrapper
) ps(ProductStatus)
/
select
    fu.id as ClientId
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,fu.emailaddress as Email
    ,fu.MobilePhone as PhoneNumber
    ,fu.DateRegistred
    ,p.Amount as LastCreditAmount
    ,p.DatePaid as LastCreditDatePaid
    ,st.TariffName as STTariffName
    ,st.TariffEndDate as STTariffEndDate
    ,st.IsLatest as STIsLatest
    ,lt.TariffName as LTTariffName
    ,lt.TariffEndDate as LTTariffEndDate
    ,lt.IsLatest as LTIsLatest
    ,l.ClientStatus as LimeClientStatus
    ,l.ProductStatus as LimeProductStatus
    ,m.ClientStatus as MangoClientStatus
    ,m.ProductStatus as MangoProductStatus
    ,s.score
from dbo.br1660DefaultList ul
inner join dbo.FrontendUsers fu on fu.id = ul.ClientId
inner join "BOR-LIME".Borneo.dbo.br1660OtherSystemStatus l on l.clientid = ul.clientid
    and l.ProductName = 'KONGA'
inner join "MANGO-DB".LimeZaim_Website.dbo.br1660OtherSystemStatus m on m.clientid = ul.clientid
    and m.ProductName = 'KONGA'
left join #th st on st.ClientId = ul.ClientId
    and st.ProductType = 1
left join #th lt on lt.ClientId = ul.ClientId
    and lt.ProductType = 2
left join dbo.br1660Score s on s.UserID = ul.ClientId
outer apply
(
    select top 1
        c.DatePaid
        ,c.Amount
    from dbo.Credits c
    where c.UserId = ul.ClientId
    order by c.DatePaid desc
) p
where (l.ProductStatus not like N'%"Просрочен"%' and l.ProductStatus not like N'%"Активен"%' and l.ProductStatus not like N'%"На реструктуризации"%' or l.ProductStatus is null)
    and (m.ProductStatus not like N'%"Просроченный"%' and m.ProductStatus not like N'%"Активный"%' or m.ProductStatus is null)
    
    
