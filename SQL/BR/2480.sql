drop table if exists dbo.br2480
;

select c.clientid
into dbo.br2480
from client.vw_Client c
cross apply
(
    select top 1 
        crr.Score
    from cr.CreditRobotResult crr
    where crr.ClientId = c.clientid
    order by crr.CreatedOn desc 
) crr
outer apply
(
    select top 1 1 as hadCredit
    from prd.vw_Product p
    where p.ClientId = c.clientid
        and p.status != 1
) p
where c.DateRegistered >= '20180501'
    and c.status = 3
    and crr.Score between 0.55 and 0.7
;

select
    ush.* --update ush set IsLatest = 0
from client.UserStatusHistory ush
inner join dbo.br2480 b on b.clientid = ush.ClientId
where ush.IsLatest = 1
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
from dbo.br2480 f
*/
;

select f.*
-- update c set c.status = 2, c.substatus = 203, c.UserBlockingPeriod = 0
from dbo.br2480 f
inner join client.Client c on c.id = f.ClientId
;

select f.*
-- update ustt set ustt.IsLatest = 0
from dbo.br2480 f
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
    ,3 as TariffId
    ,getdate() as CreatedOn
    ,cast(0x44 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
from dbo.br2480 f
;
*/


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
from dbo.br2480 f
inner join client.vw_client c on c.clientid = f.ClientId
inner join prd.ShortTermTariff stt on stt.id = 3

insert dbo.CustomListUsers
(
    CustomlistID
    ,ClientId
    ,DateCreated
    ,CustomField1
)
select
    1073
    ,ClientId
    ,cast(getdate() as date)
    ,3
from dbo.br2480 
