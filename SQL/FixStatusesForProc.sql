drop table if exists #c
;

drop table if exists #c2
;

select
    c.id
    ,c.AdminProcessingFlag
    ,c.Substatus as ClientSubstatus
    ,isnull(th.HasTariff, 0) as HasTariff
    ,isnull(p.HasCredit, 0) as HasCredit
into #c
from client.Client c
outer apply
(
    select top 1 1 as HasTariff
    from client.vw_TariffHistory th 
    where th.ClientId = c.id
        and th.IsLatest = 1
) th
outer apply
(
    select top 1 1 as HasCredit
    from prd.vw_product p
    where p.ClientId = c.id
        and p.Status not in (1, 5)
) p
where c.Status = 2
    and c.Substatus != 201
;

create index IX_Substatus on #c(ClientSubstatus)
;

select *
into #c2
from
(
    select *, 204 as NeededSubStatus
    from #c c 
    where c.ClientSubstatus != 204 
        and c.HasCredit = 1
    
    union all
    
    select *, 203 as NeededSubStatus
    from #c c 
    where c.ClientSubstatus != 203 
        and c.HasCredit = 0 
        and c.HasTariff = 1
) c
;
/
select c.* -- update cl set cl.Substatus = c.NeededSubStatus
from #c2 c
inner join client.Client cl on cl.id = c.id 
where cl.Substatus = c.ClientSubstatus
;

select c.* -- update ush set ush.IsLatest = 0, ush.ModifiedOn = getdate(), ush.ModifiedBy = cast(0x44 as uniqueidentifier)
from #c2 c
inner join client.Client cl on cl.id = c.id 
inner join client.UserStatusHistory ush on ush.ClientId = c.id
    and ush.IsLatest = 1
where cl.Substatus = c.NeededSubStatus
;


--insert into client.UserStatusHistory (ClientId,Status,IsLatest,CreatedOn,CreatedBy,BlockingPeriod,Substatus)
select
    c.id as ClientId
    , 2 as Status
    , 1 as IsLatest
    , getdate() as CreatedOn
    , cast(0x44 as uniqueidentifier) as CreatedBy
    , 0 as BlockingPeriod
    , c.NeededSubStatus
from #c2 c
inner join client.Client cl on cl.id = c.id 
where cl.Substatus = c.NeededSubStatus
/
select *
from #c2