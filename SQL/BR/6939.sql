drop table if exists #clist
;

select
    c.id as ClientId
    , th.HasTariff
into #clist
from client.Client c
outer apply
(
    select top 1 1 as HasTariff 
    from client.vw_TariffHistory th
    where th.ClientId = c.id
        and th.IsLatest = 1
) th
where c.Substatus = 204
    and not exists 
    (
        select 1 from prd.vw_product p
        where p.ClientId = c.id
            and p.Status not in (1, 5)
    )
;

/

select cl.*
--update c set SubStatus = iif(cl.HasTariff = 1, 203, 202)
from #clist cl
inner join client.Client c on c.id = cl.ClientId

select ush.*
-- update ush set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from client.UserStatusHistory ush
inner join #clist cl on cl.ClientId = ush.ClientId
where ush.IsLatest = 1 

--insert into client.UserStatusHistory (ClientId,Status,IsLatest,CreatedOn,CreatedBy,BlockingPeriod,Substatus)
select
    ClientId
    , 2
    , 1 as IsLatest
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 0
    , iif(cl.HasTariff = 1, 203, 202)
from #clist cl
/

select top 100 *
from client.UserStatusHistory
order by id desc