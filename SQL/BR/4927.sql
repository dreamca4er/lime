/*
create table dbo.br4927
(
    ClientId int
    ,ST nvarchar(20)
    ,LT nvarchar(20)
)

update dbo.br4927 
set ST = 'Silver2'
where ST = 'Siver2'
*/
drop table if exists #c
;

select 
    c.ClientId
    ,cl.Substatus
    ,stt.id as ST
    ,ltt.id as LT
    ,stt.Name as STName
    ,ltt.Name as LTName
    ,iif(LT = N'Заблокировано', 1, 0) as LTBlocked
    ,stt.MaxAmount as STMax
    ,ltt.MaxAmount as LTMax
    ,stt.PercentPerDay as STPerc
    ,ltt.PercentPerDay as LTPerc
into #c
from dbo.br4927 c
inner join client.Client cl on cl.id = c.ClientId
left join prd.ShortTermTariff stt on stt.Name = c.ST
left join prd.LongTermTariff ltt on ltt.Name = c.LT
where not exists 
    (
        select 1 from prd.vw_product p
        where p.ClientId = c.ClientId
            and p.Status in (2, 3, 4, 7)
    )
    and cl.Status = 2
    and cl.IsFrauder = 0
    and cl.IsDead = 0
    and cl.IsCourtOrdered = 0
    and cl.DebtorProhibitInteractionType = 0
    and cl.AdminProcessingFlag != 1
;
/
select * -- update  s set islatest = 1
from client.UserShortTermTariff s
where ModifiedBy = cast(0x44 as uniqueidentifier)
    and ModifiedOn >= '20181122 09:00'
    
select * -- update  s set islatest = 1
from client.UserLongTermTariff s
where ModifiedBy = cast(0x44 as uniqueidentifier)
    and ModifiedOn >= '20181122 09:00'
/
select c.* -- update t set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = cast(0x44 as uniqueidentifier)
from #c c
inner join client.UserShortTermTariff t on c.ClientId = t.ClientId
    and t.IsLatest = 1
where c.ST is not null
;

select c.* -- update t set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = cast(0x44 as uniqueidentifier)
from #c c
inner join client.UserLongTermTariff t on c.ClientId = t.ClientId
    and t.IsLatest = 1
where c.LT is not null
;

--insert client.UserShortTermTariff
(
    ClientId,TariffId,CreatedOn,CreatedBy,IsLatest
)
select
    ClientId
    ,ST as TariffId
    ,getdate() as CreatedOn
    ,cast(0x44 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
from #c c
where c.ST is not null
;


--insert client.UserLongTermTariff
(
    ClientId,TariffId,CreatedOn,CreatedBy,IsLatest
)
select
    ClientId
    ,LT as TariffId
    ,getdate() as CreatedOn
    ,cast(0x44 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
from #c c
where c.LT is not null
;

select upb.* -- update upb set BlockingPeriod = 0, ModifiedOn = getdate(), ModifiedBy = cast(0x44 as uniqueidentifier)
from client.UserProductBlock upb
inner join #c c on c.ClientId = upb.ClientId
where c.LT is not null
    and isnull(upb.BlockingPeriod, 0) > 0
;
    
select
    upb.*
from #c c
left join client.UserProductBlock upb on upb.ClientId = c.ClientId
where c.LTBlocked = 1
    and upb.BlockingPeriod is null

/


select * -- update ush set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = cast(0x44 as uniqueidentifier)
from #c c
inner join client.UserStatusHistory ush on ush.ClientId = c.ClientId
    and ush.IsLatest = 1
where (c.ST is not null
    or c.LT is not null)
    and c.Substatus = 203
;
select top 10 *
--insert into client.UserStatusHistory ush
(
    ClientId,Status,IsLatest,CreatedOn,CreatedBy,BlockingPeriod,Substatus
)
select
    ClientId
    ,2 as Status
    ,getdate() as CreatedOn
    ,cast(0x44 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
    ,20
from #c c
where c.ST is not null
    or c.LT is not null
    /
select
    cl.ClientId
    ,cl.LastName
    ,cl.FirstName
    ,cl.FatherName
    ,cl.PhoneNumber
    ,cl.Email
    ,c.STName
    ,c.LTName
    ,c.STMax
    ,c.LTMax
    ,c.STPerc
    ,c.LTPerc
from #c c
inner join client.vw_Client cl on cl.ClientId = c.ClientId

insert dbo.CustomListUsers
(
    CustomlistID,ClientId,DateCreated,CustomField1,CustomField2
)
select
    1089
    ,ClientId
    ,getdate()
    ,ST
    ,LT
from #c