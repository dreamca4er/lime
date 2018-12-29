select avg(score),sum(score * cnt) / sum(cnt)
from
(
    select 
        cast(score as numeric(3, 2)) as score
        , count(*) as cnt
    from 
    (
        select 
            b.ClientId
            , crr.Score
        from br6046 b
        outer apply
        (
            select top 1 crr.Score
            from cr.CreditRobotResult crr
            where crr.ClientId = b.ClientId
            order by crr.CreatedOn desc
        ) crr
        where b.Action not in (N'нет данных', '-', N'ничего не делать')
            and b.Action = N'Блок'
            and not exists 
                (
                    select 1 from prd.vw_product p
                    where p.Status not in (1, 5)
                        and p.ClientId = b.ClientId 
                )
    )
     b
group by cast(score as numeric(3, 2))
) a

/
/*
select *
from dbo.CustomList
where id = 1106
*/

--insert dbo.CustomListUsers (ClientId, CustomlistID, DateCreated)
select distinct
    b.ClientId
    , 1106 as CustomListId
    , '20181228'
-- delete u
from br6046 b
inner join dbo.CustomListUsers u on u.ClientId = b.ClientId
outer apply
(
    select top 1 crr.Score
    from cr.CreditRobotResult crr
    where crr.ClientId = b.ClientId
    order by crr.CreatedOn desc
) crr
where b.Action not in (N'нет данных', '-', N'ничего не делать')
    and b.Action = N'Блок'
    and not exists 
        (
            select 1 from prd.vw_product p
            where p.Status not in (1, 5)
                and p.ClientId = b.ClientId 
        )
    and
    (
        u.CustomlistID in (1096,1095,1094,1093,1092)
        or u.CustomlistID in (1101,1100,1099,1098,1097)        
    )
;
/
-- Блок
select * -- update ustt set ModifiedOn = getdate(), ModifiedBy = 0x44, IsLatest = 0
from dbo.CustomListUsers u
inner join client.UserShortTermTariff ustt on ustt.ClientId = u.ClientId
    and ustt.IsLatest = 1
where CustomlistID = 1106

select * -- update ultt set ModifiedOn = getdate(), ModifiedBy = 0x44, IsLatest = 0
from dbo.CustomListUsers u
inner join client.UserLongTermTariff ultt on ultt.ClientId = u.ClientId
    and ultt.IsLatest = 1
where CustomlistID = 1106

select * -- update ush set IsLatest = 0
from client.UserStatusHistory ush
inner join dbo.CustomListUsers u on u.ClientId = ush.ClientId
    and u.CustomlistID = 1106
where ush.IsLatest = 1

--insert into client.UserStatusHistory (ClientId,Status,IsLatest,CreatedOn,CreatedBy,BlockingPeriod,Substatus)
select
    ClientId
    , 2 as Status
    , 1 as IsLatest
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 0 as BlockingPeriod
    , 202 as Substatus
from dbo.CustomListUsers u
where CustomlistID = 1106

select u.ClientId, ush.Substatus, cl.Substatus -- update cl set cl.Substatus = 202
from dbo.CustomListUsers u
inner join client.UserStatusHistory ush on ush.ClientId = u.ClientId
    and ush.IsLatest = 1
inner join client.Client cl on cl.id = ush.ClientId 
where u.CustomlistID = 1106
/
drop table if exists #t
;

with t as 
(
    select distinct 
        b.ClientId
        , cl.Substatus
        , cl.substatusName
        , isnull(st.Id, lt.id) as TariffId
        , iif(st.Id is not null, 1, 2) as ProductType
        , iif(st.Id is not null, concat(st.GroupName, '\', st.Name), concat(lt.GroupName, '\', lt.Name)) as TariffName
        , isnull(st.MaxAmount, lt.MaxAmount) as MaxAmount
        , isnull(ust.TariffId, ult.TariffId) as CurrentTariffId
    from br6046 b
    left join client.vw_client cl on cl.clientid = b.ClientId
    left join prd.ShortTermTariff st on concat(st.GroupName, '\', st.Name) = b.Action
    left join prd.LongTermTariff lt on concat(lt.GroupName, '\', lt.Name) = b.Action
    left join dbo.CustomListUsers unb on unb.ClientId = b.ClientId
        and unb.CustomlistID in (1105, 1106)
    left join client.vw_TariffHistory ust on ust.ClientId = b.ClientId
        and ust.IsLatest = 1
        and ust.ProductType = 1
        and st.id is not null
    left join client.vw_TariffHistory ult on ult.ClientId = b.ClientId
        and ult.IsLatest = 1
        and ult.ProductType = 2
        and lt.id is not null
    where b.Action not in (N'нет данных', '-', N'ничего не делать', N'ничего не делать')
        and unb.ClientId is null
        and isnull(st.Id, lt.id) is not null
        and not exists 
        (
            select 1 from prd.vw_product p
            where p.Status not in (1, 5)
                and p.ClientId = b.ClientId 
        )
        and cl.status = 2
)   

select *
into #t
from t
;

select * -- update ut set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from #t t
inner join client.UserShortTermTariff ut on ut.ClientId = t.ClientId
    and ut.IsLatest = 1
where t.ProductType = 1
;

select * -- update ut set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from #t t
inner join client.UserLongTermTariff ut on ut.ClientId = t.ClientId
    and ut.IsLatest = 1
where t.ProductType = 2
;

--insert into client.UserShortTermTariff (ClientId,TariffId,CreatedOn,CreatedBy,IsLatest)
select distinct
    ClientId
    , t.TariffId
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 1 as IsLatest
from #t t
where t.ProductType = 1
;

--insert into client.UserLongTermTariff (ClientId,TariffId,CreatedOn,CreatedBy,IsLatest)
select distinct
    ClientId
    , t.TariffId
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 1 as IsLatest
from #t t
where t.ProductType = 2
;

select t.* -- update ush set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from #t t
inner join client.UserStatusHistory ush on ush.ClientId = t.ClientId
    and ush.IsLatest = 1
    and ush.Substatus != 203
;

--insert into client.UserStatusHistory (ClientId,Status,IsLatest,CreatedOn,CreatedBy,BlockingPeriod,Substatus)
select distinct
    ClientId
    , 2 as Status
    , 1 as IsLatest
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 0 as BlockingPeriod
    , 203 as Substatus 
from #t t
where not exists 
    (
        select 1 from client.UserStatusHistory ush
        where ush.ClientId = t.ClientId
            and ush.IsLatest = 1
            and ush.Substatus = 203
    )
;

select t.* -- update c set status = 203
from #t t
inner join client.Client c on c.id = t. ClientId
/
--1107

--insert into dbo.CustomListUsers (CustomlistID,ClientId,DateCreated,CustomField1,CustomField2)
select distinct
    1107 as CustomlistID
    , c.ClientId
    , getdate() as DateCreated
    , ust.TariffId as CustomField1
    , ult.TariffId as CustomField2
from (select distinct ClientId from dbo.br6046Upped) c
left join dbo.br6046Upped ust on ust.ClientId = c.ClientId
    and ust.ProductType = 1
left join dbo.br6046Upped ult on ult.ClientId = c.ClientId
    and ult.ProductType = 2
/

select 
    count(*) as ClientCount
    , count(CustomField1) as ShortTermReassigned
    , count(CustomField2) as LongTermReassigned
from dbo.CustomListUsers
where CustomlistID = 1107



outer apply
(
    select 
        count(*) as TariffUnassign
    from dbo.CustomListUsers 
    where CustomlistID = 1106
) t
/
select
    c.clientid
    , c.LastName
    , c.FirstName
    , c.FatherName
    , c.PhoneNumber
    , iif(c.EmailConfirmed = 1, c.Email, null) as Email
    , sth.TariffName as STTariff
    , sth.MaxAmount as STMaxAmount
    , lth.TariffName as LTTariff
    , lth.MaxAmount as LTMaxAmount
from dbo.CustomListUsers u
inner join client.vw_client c on c.clientid = u.ClientId
left join client.vw_TariffHistory sth on sth.ClientId = u.ClientId
    and sth.IsLatest = 1
    and sth.ProductType = 1
left join client.vw_TariffHistory lth on lth.ClientId = u.ClientId
    and lth.IsLatest = 1
    and lth.ProductType = 2
where u.CustomlistID = 1107
/

select *
from doc.CompanyDetails