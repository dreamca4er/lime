drop table if exists dbo.br2445
;

drop table if exists dbo.br2445Fin
;

select
    c.Id as ClientId
    ,c.AdminProcessingFlag
    ,c.Substatus
    ,case
        when crr.Score > 0.9 then 6
        when crr.Score > 0.8 then 5
        when crr.Score > 0.7 then 4
        when crr.Score > 0.6 then 3
    end as TariffId
into dbo.br2445
from cr.CreditRobotResult crr
inner join client.Client c on c.Id = crr.ClientId
    and c.IsFrauder = 0
    and c.IsDead = 0
    and c.IsCourtOrdered = 0
    and c.Status = 2
where not exists 
    (
        select 1 from cr.CreditRobotResult crr2
        where crr2.ClientId = crr.ClientId
            and crr2.CreatedOn > crr.CreatedOn
    )
    and crr.Score > 0.6
    and not exists 
    (
        select 1 from prd.vw_product p
        where p.ClientId = crr.ClientId
            and p.Status in (2, 3, 4, 7)
    )
    and crr.CreatedOn >= '20180701'
;

select
    b.ClientId
    ,b.TariffId
into dbo.br2445Fin
from dbo.br2445 b
left join client.UserShortTermTariff ustt on ustt.ClientId = b.ClientId
    and ustt.IsLatest = 1
where ustt.TariffId is null
    or ustt.TariffId <= b.TariffId
;

select f.*
-- update ustt set ustt.IsLatest = 0
from dbo.br2445Fin f
inner join client.UserShortTermTariff ustt on ustt.ClientId = f.ClientId
    where ustt.IsLatest = 1
;
/*
insert into client.UserShortTermTariff
(
    ClientId, TariffId, CreatedOn, CreatedBy, IsLatest
)
select
    f.ClientId
    ,f.TariffId
    ,getdate() as CreatedOn
    ,cast(0x44 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
from dbo.br2445Fin f
;
*/

select
    f.*
-- update ush set ush.IsLatest = 0
from dbo.br2445Fin f
inner join client.Client c on c.id = f.ClientId
inner join client.UserStatusHistory ush on ush.ClientId = f.ClientId
    and ush.IsLatest = 1
where c.Substatus = 201
;

/*
insert into client.UserStatusHistory
(
    ClientId, Status, Substatus, IsLatest, CreatedOn, CreatedBy, BlockingPeriod
)
select
    f.ClientId
    ,2 as Status
    ,203 as Substatus
    ,1 as IsLatest
    ,getdate() as CreatedOn
    ,cast(0x44 as uniqueidentifier) as CreatedBy
    ,0 as BlockingPeriod
from dbo.br2445Fin f
inner join client.Client c on c.id = f.ClientId
where c.Substatus = 201
*/

select f.*
-- update c set c.substatus = 203, c.AdminProcessingFlag = 4
from dbo.br2445Fin f
inner join client.Client c on c.id = f.ClientId
where c.Substatus = 201

select
    c.clientid
    ,c.LastName
    ,c.FirstName
    ,c.FatherName
    ,c.PhoneNumber
    ,c.Email
    ,stt.Name as TariffName
    ,stt.MaxAmount
    ,stt.PercentPerDay
from dbo.br2445Fin f
inner join client.vw_client c on c.clientid = f.ClientId
inner join prd.ShortTermTariff stt on stt.id = f.TariffId

insert dbo.CustomListUsers
(
    CustomlistID
    ,ClientId
    ,DateCreated
    ,CustomField1
)
select
    1071
    ,ClientId
    ,cast(getdate() as date)
    ,TariffId
from dbo.br2445fin 
