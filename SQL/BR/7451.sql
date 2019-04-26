select *
from dbo.CustomList
--insert dbo.CustomListUsers (CustomlistID,ClientId,DateCreated,CustomField1,CustomField2)
select
    1116 as CustomlistID
    , ClientId
    , getdate() as DateCreated
    , TariffId as CustomField1
    , null as CustomField2
from dbo.br7451 b
outer apply
(
    select top 1 th.TariffId
    from client.vw_TariffHistory th
    where th.ClientId = b.ClientId
        and th.ProductType = 1
        and th.IsLatest = 1
    order by th.CreatedOn desc
) st

/

--insert into client.UserShortTermTariff (ClientId,TariffId,CreatedOn,CreatedBy,IsLatest)
select
    ClientId
    , st.TariffId
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 1 as IsLatest
from dbo.br7451 b
outer apply
(
    select top 1
        th.IsLatest
        , th.TariffId
    from client.vw_TariffHistory th
    where th.ClientId = b.ClientId
        and th.ProductType = 1
    order by th.CreatedOn desc
) st
where not exists
    (
        select 1 from client.UserShortTermTariff ustt
        where ustt.ClientId = b.ClientId
            and ustt.IsLatest = 1
    )
;


select
    c.Id
    , c.Status
    , c.Substatus
    , c.UserBlockingPeriod
-- update c set Status = 2, Substatus = 203, UserBlockingPeriod = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from dbo.br7451 b
inner join Client.Client c on b.ClientId = c.id
;


select *
-- update ush set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from dbo.br7451 b
inner join client.UserStatusHistory ush on b.ClientId = ush.ClientId
    and ush.IsLatest = 1
;

--insert into client.UserStatusHistory (ClientId,Status,IsLatest,CreatedOn,CreatedBy,BlockingPeriod,Substatus)
select
    ClientId
    , 2
    , 1 as IsLatest
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 0 as BlockingPeriod
    , 203 as Substatus
from dbo.br7451 b
/

select *
from dbo.br7451 b