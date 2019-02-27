drop table if exists #lime
;

select 
    p.clientid
    , c.Passport
into #lime
from prd.vw_AllProducts p
inner join client.vw_Client c on c.clientid = p.ClientId
where not exists 
    (
        select 1 from prd.vw_product p2
        where p2.ClientId = p.ClientId
            and p2.Status not in (1, 5)
    )
    and c.IsDead = 0
    and c.IsCourtOrdered = 0
    and c.IsFrauder = 0
    and c.status = 2
    and not exists 
        (
            select 1 from dbo.br6317_oth oth
            where oth.Passport = c.Passport
                and (oth.ProductStatus not like N'Погашен%' or 1 in (oth.IsDead, oth.IsFrauder, oth.IsCourtOrdered))
        )
group by p.ClientId, c.Passport
having max(p.DatePaid) >= '20170701'
    and max(p.DatePaid) < '20180601'
    and avg(datediff(d, p.StartedOn, p.DatePaid)) > 5
;

drop table if exists dbo.br6317_ch
;

select
    c.clientid
    , c.LastName
    , c.FirstName
    , c.FatherName
    , iif(c.EmailConfirmed = 1, c.Email, null) as Email
    , c.PhoneNumber
    , cast(c.DateRegistered as date) as DateRegistered
    , ustt.TariffId as STTariffID
    , ustt.TariffName as STTariff
    , ustt.IsLatest as STIsLatest
    , ultt.TariffId as LTTariffID
    , ultt.TariffName as LTTariff
    , ultt.IsLatest as LTIsLatest
    , s.Score
    , datediff(d, s.CreatedOn, getdate()) as ScoreAge
    , N'Погашен' as LimeProductStatus
    , left(Mango.ProductStatus, 7) as MangoProductStatus
    , left(Konga.ProductStatus, 7) as KongaProductStatus
into dbo.br6317_ch
from #lime l
left join client.vw_client c on c.clientid = l.ClientId 
outer apply
(
    select top 1 *
    from dbo.br6317_oth oth
    where oth.Passport = l.Passport
        and oth.Project = 'Mango'
    order by case when oth.ProductStatus is null then 2 else 1 end
) Mango
outer apply
(
    select top 1 *
    from dbo.br6317_oth oth
    where oth.Passport = l.Passport
        and oth.Project = 'Konga'
    order by case when oth.ProductStatus is null then 2 else 1 end
) Konga
outer apply
(
    select top 1
        ut.TariffId
        , ut.TariffName
        , ut.IsLatest
    from client.vw_TariffHistory ut
    where ut.ClientId = l.ClientId
        and ut.ProductType = 1
    order by case when ut.IsLatest = 1 then 1 else 2 end
        , ut.CreatedOn desc
) ustt
outer apply
(
    select top 1
        ut.TariffId
        , ut.TariffName
        , ut.IsLatest
    from client.vw_TariffHistory ut
    where ut.ClientId = l.ClientId
        and ut.ProductType = 2
    order by case when ut.IsLatest = 1 then 1 else 2 end
        , ut.CreatedOn desc
) ultt
outer apply
(
    select top 1 
        crr.Score
        , crr.CreatedOn
    from cr.CreditRobotResult crr
    where crr.Score > 0
        and crr.ClientId = l.ClientId
    order by crr.CreatedOn desc
) s
/


-- 1109
--insert dbo.CustomListUsers (CustomlistID,ClientId,DateCreated,CustomField1,CustomField2)
select
    1109 as CustomlistID
    , ClientId
    , getdate() as DateCreated
    , null as CustomField1
    , null as CustomField2
from dbo.br6317_ch
where ScoreAge is null or ScoreAge > 30

select * 
from dbo.CustomListUsers
where CustomlistID = 1109
/

insert cr.CreditRobotResult
(
    ClientId,CreatedOn,AnalysisResult,Score
)
select
    UserID
    , '20190122 12:54:57'
    , 1
    , Score
from dbo.br6317_score

/

select *
from cr.CreditRobotResult c
where CreatedOn = '20190122 08:54:57'
/

select s.*
from dbo.br6359 t
inner join dbo.br6317_ch s on s.clientid = t.ClientId
where t.Team = 'A'
/
select *
into bi.TariffUpdateRools
from 
(
    select
        id as TariffId
        , Name as TariffName
        , 1 as ProductType
        , cast(null as numeric(4, 3)) as ScoreFrom
        , cast(null as numeric(4, 3)) as ScoreTo
        , null as NewTariffId
    from prd.ShortTermTariff
    
    union all
    
    select
        id as TariffId
        , Name as TariffName
        , 2 as ProductType
        , cast(null as numeric(4, 3)) as ScoreFrom
        , cast(null as numeric(4, 3)) as ScoreTo
        , null as NewTariffId
    from prd.LongTermTariff
) a
/
drop table if exists #a
;

drop table if exists #b
;

select 
    tus.NewTariffId as STTariffID
    , tul.NewTariffId as LTTariffID
    , s.clientid
into #a
from dbo.br6359 t
inner join client.Client c on c.id = t.ClientId
    and c.Status = 2
inner join dbo.br6317_ch s on s.clientid = t.ClientId
inner join bi.TariffUpdateRools tus on tus.ProductType = 1
    and s.Score >= tus.ScoreFrom 
    and s.Score < tus.ScoreTo
    and s.STTariffID = tus.TariffId
left join bi.TariffUpdateRools tul on tul.ProductType = 2
    and s.Score >= tul.ScoreFrom 
    and s.Score < tul.ScoreTo
    and s.LTTariffID = tul.TariffId
where t.Team = 'A'
    and not exists 
        (
            select 1 from prd.vw_product p
            where p.ClientId = t.ClientId
                and p.Status not in (1, 5)
        )
;

select 
    s.STTariffID
    , s.LTTariffID
    , s.clientid
into #b
from dbo.br6359 t
inner join client.Client c on c.id = t.ClientId
    and c.Status = 2
inner join dbo.br6317_ch s on s.clientid = t.ClientId
where t.Team = 'B'
    and not exists 
        (
            select 1 from prd.vw_product p
            where p.ClientId = t.ClientId
                and p.Status not in (1, 5)
        )
;

/

drop table if exists #un
;

select *
into #un
from #b
;

select un.*
-- update c set Substatus = 203
from #un un
inner join client.Client c on c.id = un.ClientId 
;

select *
-- update ush set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from #un un
inner join client.UserStatusHistory ush on ush.ClientId = un.ClientId
where ush.IsLatest = 1
;

--insert into client.UserStatusHistory (ClientId,Status,IsLatest,CreatedOn,CreatedBy,BlockingPeriod,Substatus)
select
    ClientId
    , 2 as Status
    , 1 as IsLatest
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 0 as BlockingPeriod
    , 203 as Substatus
from #un
;

select un.*
-- update ut set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from #un un
inner join client.UserShortTermTariff ut on ut.ClientId = un.ClientId
    and ut.IsLatest = 1
;
    
select un.*
-- update ut set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from #un un
inner join client.UserLongTermTariff ut on ut.ClientId = un.ClientId
    and ut.IsLatest = 1
;

--insert into client.UserShortTermTariff (ClientId,TariffId,CreatedOn,CreatedBy,IsLatest)
select
    ClientId
    , STTariffID
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 1 as IsLatest
from #un
where STTariffID is not null
;

--insert into client.UserLongTermTariff (ClientId,TariffId,CreatedOn,CreatedBy,IsLatest)
select
    ClientId
    , LTTariffID
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 1 as IsLatest
from #un
where LTTariffID is not null
;
/

select
    c.clientid
    , c.LastName
    , c.FirstName
    , c.FatherName
    , iif(c.EmailConfirmed = 1, c.Email, null) as Email
    , c.PhoneNumber
    , cast(c.DateRegistered as date) as DateRegistered
    , ustt.TariffId as STTariffID
    , ustt.TariffName as STTariff
    , ustt.IsLatest as STIsLatest
    , ultt.TariffId as LTTariffID
    , ultt.TariffName as LTTariff
    , ultt.IsLatest as LTIsLatest
    , s.Score
    , datediff(d, s.CreatedOn, getdate()) as ScoreAge
    , N'Погашен' as LimeProductStatus
    , left(Mango.ProductStatus, 7) as MangoProductStatus
    , left(Konga.ProductStatus, 7) as KongaProductStatus
    , iif(ultt.maxAmount > ustt.maxAmount, ultt.maxAmount, ustt.MaxAmount) as MaxAmount
from #a l
left join client.vw_client c on c.clientid = l.ClientId 
outer apply
(
    select top 1 *
    from dbo.br6317_oth oth
    where oth.Passport = c.Passport
        and oth.Project = 'Mango'
    order by case when oth.ProductStatus is null then 2 else 1 end
) Mango
outer apply
(
    select top 1 *
    from dbo.br6317_oth oth
    where oth.Passport = c.Passport
        and oth.Project = 'Konga'
    order by case when oth.ProductStatus is null then 2 else 1 end
) Konga
outer apply
(
    select top 1
        ut.TariffId
        , ut.TariffName
        , ut.IsLatest
        , ut.MaxAmount
    from client.vw_TariffHistory ut
    where ut.ClientId = l.ClientId
        and ut.ProductType = 1
    order by case when ut.IsLatest = 1 then 1 else 2 end
        , ut.CreatedOn desc
) ustt
outer apply
(
    select top 1
        ut.TariffId
        , ut.TariffName
        , ut.IsLatest
        , ut.MaxAmount
    from client.vw_TariffHistory ut
    where ut.ClientId = l.ClientId
        and ut.ProductType = 2
    order by case when ut.IsLatest = 1 then 1 else 2 end
        , ut.CreatedOn desc
) ultt
outer apply
(
    select top 1 
        crr.Score
        , crr.CreatedOn
    from cr.CreditRobotResult crr
    where crr.Score > 0
        and crr.ClientId = l.ClientId
    order by crr.CreatedOn desc
) s



select *
from #b
/

1111	22.01.2019 Повышение шага тарифа А
1110	22.01.2019 Повышение шага тарифа Б

/


insert dbo.CustomListUsers (CustomlistID,ClientId,DateCreated,CustomField1,CustomField2)
select
    1110 as CustomlistID
    , ClientId
    , getdate() as DateCreated
    , STTariffID as CustomField1
    , LTTariffID as CustomField2
from #b