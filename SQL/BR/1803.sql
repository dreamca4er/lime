/*
drop table if exists #list
;

drop table if exists #t
;

drop table if exists #FinListSTUpdate
;

drop table if exists #FinListSTCreate
;
*/
select
    id as TariffId
    ,GroupName + '/' + Name as TariffName
    ,MaxAmount
    ,row_number() over (order by cast(SortOrder as numeric(10,2))) as TariffOrder
    ,count(*) over () as TariffCount
--into #t
from prd.ShortTermTariff stt
;

select
    th.id
    ,th.ClientId
    ,th.ProductType
    ,th.TariffId
    ,max(case when th.ProductType = 1 then #t.TariffOrder end) over (partition by th.ClientId)as STTariffOrder
--into #list
from client.vw_TariffHistory th
inner join client.vw_client c on c.clientid = th.ClientId
    and c.status < 3
left join #t on #t.TariffId = th.TariffId
    and th.ProductType = 1
where th.IsLatest = 1
    and not exists 
        (
            select 1 from prd.vw_product p
            where p.ClientId = th.ClientId
                and p.status not in (1, 5)
        )
    and (th.ProductType != 2 
            or not exists 
                (
                    select 1 from client.vw_TariffHistory th2
                    where th2.ClientId = th.ClientId
                        and th2.ProductType = 1
                        and th2.IsLatest = 1
                ))
;


select
    l.id as OldId
    ,l.ClientId
    ,l.TariffId as OldTariffId
    ,#t.TariffId as NewTariffId
--into #FinListSTUpdate
from #list l
inner join #t on 
    l.STTariffOrder + 2 < #t.TariffCount
        and #t.TariffOrder = l.STTariffOrder + 2
    or l.STTariffOrder + 2 >= #t.TariffCount
        and #t.TariffOrder = #t.TariffCount
;


select
    l.ClientId
    ,l.STTariffOrder as OldTariffId
    ,#t.TariffId as NewTariffId
--into #FinListSTCreate
from #list l, #t
where l.STTariffOrder is null
    and #t.TariffOrder = 2
;
/

select ustt.* -- update ustt set IsLatest = 0
from #FinListSTUpdate fl
inner join client.UserShortTermTariff ustt on ustt.id = fl.OldId
;

--insert client.UserShortTermTariff (ClientId, TariffId, CreatedOn, CreatedBy, IsLatest)
select
    fl.ClientId
    ,fl.NewTariffId as TariffId
    ,getdate() as CreatedOn
    ,cast(0x44 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
from #FinListSTUpdate fl

union

select 
    fl.ClientId
    ,fl.NewTariffId as TariffId
    ,getdate() as CreatedOn
    ,cast(0x44 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
from #FinListSTCreate fl

/
with l as 
(
    select
        st.ClientId
        ,stto.TariffName as OldTariff
        ,sttn.TariffName as NewTariff
        ,stto.MaxAmount as OldMaxAmount
        ,sttn.MaxAmount as NewMaxAmount
    from #FinListSTUpdate st
    inner join #t stto on stto.TariffId = st.OldTariffId
    inner join #t sttn on sttn.TariffId = st.NewTariffId
    
    union all
    
    select
        st.ClientId
        ,stto.TariffName as OldTariff
        ,sttn.TariffName as NewTariff
        ,stto.MaxAmount as OldMaxAmount
        ,sttn.MaxAmount as NewMaxAmount
    from #FinListSTCreate st
    inner join #t sttn on sttn.TariffId = st.NewTariffId
    left join #t stto on stto.TariffId = st.OldTariffId
)

/*
select *
from dbo.CustomList


insert dbo.CustomListUsers
(
    CustomlistID, ClientId
)
select 1067, ClientId from l
*/
,rf as 
(
    select 
        crf.ClientId
    from mkt.ClientReductionFactor crf
    inner join mkt.ReductionFactor rf on rf.Id = crf.ReductionFactorId
    left join mkt.ProductReductionFactor prf on prf.ClientReductionFactorId = crf.Id
    where rf.Factor = 0
    group by crf.ClientId
    having count(prf.Id) = 0
)

select
    c.clientid
    ,c.fio
    ,c.PhoneNumber
    ,c.Email
    ,l.OldTariff
    ,l.NewTariff
    ,l.OldMaxAmount
    ,l.NewMaxAmount
    ,case when rf.ClientId is null then 0 else 1 end as HasFreeCreditPromo
from l
inner join Client.vw_client c on c.clientid = l.clientid
left join rf on rf.ClientId = c.clientid
where c.status < 3