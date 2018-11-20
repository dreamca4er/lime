drop table if exists #cl
;

with st as 
(
    select
        id
        ,ClientId
        ,Substatus
        ,lag(Status) over (partition by ClientId order by CreatedOn) as PrevStatus
        ,IsLatest
    from client.UserStatusHistory
    where CreatedOn < dateadd(minute, -5, getdate())
)

select top 20000
    st.id as UserStatusHistoryid
    ,ClientId
into #cl
--select count(*)
from st
inner join client.Client c on c.Id = st.ClientId
where st.IsLatest = 1
    and st.Substatus = 201
    and st.PrevStatus = 3
    and c.AdminProcessingFlag != 1
;

update ush set ush.islatest = 0, ush.ModifiedOn = getdate(), ush.ModifiedBy = cast(0x44 as uniqueidentifier)
from #cl cl
inner join client.UserStatusHistory ush on ush.id = cl.UserStatusHistoryid
;

insert into client.UserStatusHistory
(
    ClientId,Status,IsLatest,CreatedOn,CreatedBy,BlockingPeriod,Substatus
)
select
    ClientId
    ,2 as Status
    ,1 as IsLatest
    ,getdate() as CreatedOn
    ,cast(0x44 as uniqueidentifier) as CreatedBy
    ,0 as BlockingPeriod
    ,202 as Substatus
from #cl
;

update c set Substatus = 202
from #cl cl
inner join client.client c on c.id = cl.ClientId
;

select *
from #cl