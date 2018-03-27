with t as 
(
    select *
        ,row_number() over (order by TariffType, SortOrder) as RealOrder
    from 
    (
        select
            id as TariffId
            ,GroupName + '\' + Name as TariffName
            ,1 as TariffType
            ,SortOrder
        from prd.ShortTermTariff 
        
        union
        
        select
            id as TariffId
            ,GroupName + '\' + Name as TariffName
            ,2 as TariffType
            ,SortOrder
        from prd.LongTermTariff
    ) t
)

select
    ustt.id
    ,ustt.ClientId
    ,ustt.TariffId
    ,t.TariffName
    ,NextT.TariffType as NextTTariffType
    ,NextT.TariffId as NextTTariffId
    ,NextT.TariffName as NextTTariffName
    ,0 as processed
into  dbo.ShortTermFull
from client.UserShortTermTariff ustt
inner join t on t.TariffId = ustt.TariffId
    and t.TariffType = 1
left join t NextT on NextT.RealOrder = t.RealOrder + 2
where IsLatest = 1 
    and not exists
                (
                    select 1 from client.UserLongTermTariff ultt
                    where ultt.ClientId = ustt.ClientId
                        and ultt.IsLatest = 1
                )

;


update ustt
set islatest = 0
--select ustt.*
from  dbo.ShortTermFull t
inner join client.UserShortTermTariff ustt on ustt.id = t.id
where t.NextTTariffType = 1
;

insert into client.UserShortTermTariff
 (
    clientid, TariffId, CreatedOn, CreatedBy, IsLatest
 )
select 
    ustt.clientid
    ,t.NextTTariffId
    ,getdate() as CreatedOn
    ,cast(0x0 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
from  dbo.ShortTermFull t
inner join client.UserShortTermTariff ustt on ustt.id = t.id
where t.NextTTariffType = 1

update t
set processed = 1
from  dbo.ShortTermFull t
where t.NextTTariffType = 1
;

update ustt
set islatest = 0
--select ustt.*
from  dbo.ShortTermFull t
inner join client.UserShortTermTariff ustt on ustt.id = t.id
where t.NextTTariffType = 2

insert into client.UserLongTermTariff
 (
    clientid, TariffId, CreatedOn, CreatedBy, IsLatest
 )
select 
    t.clientid
    ,t.NextTTariffId
    ,getdate() as CreatedOn
    ,cast(0x0 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
from  dbo.ShortTermFull t
where t.NextTTariffType = 2
;

with t as 
(
    select *
        ,row_number() over (order by TariffType, SortOrder) as RealOrder
    from 
    (
        select
            id as TariffId
            ,GroupName + '\' + Name as TariffName
            ,1 as TariffType
            ,SortOrder
        from prd.ShortTermTariff 
        
        union
        
        select
            id as TariffId
            ,GroupName + '\' + Name as TariffName
            ,2 as TariffType
            ,SortOrder
        from prd.LongTermTariff
    ) t
)

select
    l.id
    ,l.clientid
    ,t.TariffId
    ,t.TariffName
    ,isnull(NextT.TariffId, 8) as NextTTariffId
    ,NextT.TariffName as NextTTariffName
into dbo.LongTermFull
from client.UserLongTermTariff l
inner join t on t.TariffId = l.TariffId
    and t.TariffType = 2
left join t NextT on NextT.RealOrder = t.RealOrder + 2
    and t.TariffId + 2 < 9
    and NextT.TariffType = 2
where not exists
            (
                select 1 from  dbo.ShortTermFull t
                where l.ClientId = t.clientid
            )
    and l.islatest = 1
    and l.TariffId < 8
    ;
    
    
update ustt
set islatest = 0
--select ustt.*
from dbo.LongTermFull t
inner join client.UserlongTermTariff ustt on ustt.id = t.id
where t.NextTTariffType = 2

insert into client.UserLongTermTariff
 (
    clientid, TariffId, CreatedOn, CreatedBy, IsLatest
 )
select 
    t.clientid
    ,t.NextTTariffId
    ,getdate() as CreatedOn
    ,cast(0x0 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
from dbo.LongTermFull t
where t.NextTTariffType = 2
/

select
    c.clientid
    ,c.fio
    ,c.Email
    ,c.PhoneNumber
    ,t.NextTTariffName
from dbo.ShortTermFull t
inner join client.vw_client c on t.ClientId = c.clientid

union

select
    c.clientid
    ,c.fio
    ,c.Email
    ,c.PhoneNumber
    ,t.NextTTariffName
from dbo.LongTermFull t
inner join client.vw_client c on t.ClientId = c.clientid
;

update  t
set MaxAmount = MaxAmount + 2000
from prd.ShortTermTariff t

update  t
set MaxAmount = MaxAmount + 2000
from prd.LongTermTariff t

