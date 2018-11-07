drop table if exists #tmp
;

select
    b.*
    ,st.Id as NewSTId
    ,lt.Id as NewLTId
    ,ustt.id as usttid
    ,ultt.id as ulttid
into #tmp
from dbo.br4170 b
left join prd.ShortTermTariff st on st.Name = b.NewST
left join prd.LongTermTariff lt on lt.Name = b.NewLT
left join Client.UserShortTermTariff ustt on ustt.ClientId = b.ClientId
    and ustt.IsLatest = 1
    and (st.Id is not null or b.NewST = 'null')    
left join Client.UserLongTermTariff ultt on ultt.ClientId = b.ClientId
    and ultt.IsLatest = 1
    and (lt.Id is not null or b.NewLT = 'null')  
where st.Id is not null
    or lt.Id is not null
    or b.NewST = 'null'
    or b.NewLT = 'null'
;
/

select t.NewST, ut.* -- update ut set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = cast(0x44 as uniqueidentifier)
from #tmp t
inner join client.UserShortTermTariff ut on ut.id = t.usttid
;

select t.NewLT, ut.* -- update ut set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = cast(0x44 as uniqueidentifier)
from #tmp t
inner join client.UserLongTermTariff ut on ut.id = t.ulttid
;

--insert client.UserShortTermTariff 
(
    ClientId,TariffId,CreatedOn,CreatedBy,IsLatest
)
select
    t.ClientId
    ,t.NewSTId
    ,getdate() as CreatedOn
    ,cast(0x44 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
from #tmp t
where t.NewSTId is not null
;

--insert client.UserLongTermTariff 
(
    ClientId,TariffId,CreatedOn,CreatedBy,IsLatest
)
select
    t.ClientId
    ,t.NewLTId
    ,getdate() as CreatedOn
    ,cast(0x44 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
from #tmp t
where t.NewLTId is not null
;
/
drop table if exists #tmp2
;

select
    b.*
    ,st.Id as NewSTId
    ,lt.Id as NewLTId
    ,th.id as usttid
    ,th.TariffName
into #tmp2
from dbo.br4170 b
left join prd.ShortTermTariff st on st.Name = b.NewST
left join prd.LongTermTariff lt on lt.Name = b.NewLT
left join Client.vw_TariffHistory th on th.ClientId = b.ClientId
    and th.IsLatest = 1
    and th.ProductType = 1
where NewST is null
    and not exists 
        (
            select 1 from prd.vw_product p
            where p.ClientId = b.ClientId
                and p.Status in (2, 3, 4, 7)
        )
;

select *
from #tmp2
/

select (10000 * 200 + 20000 * 400 + 50000 * 600) * 1.0 / (10000 + 20000 + 50000)