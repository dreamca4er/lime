/*
insert dbo.CustomListUsers
select
    1080 as CustomListId
    ,u.ClientId
    ,'20180919'
    ,stt.Id as STId
    ,ltt.Id as LTId
from dbo.br3321up1 u
left join prd.ShortTermTariff stt on stt.Name = replace(replace(u.NewSt, 'Silver\', ''), 'Start\', '')
left join prd.LongTermTariff ltt on ltt.Name = replace(u.NewLt, 'LimeUp\', '')
left join client.vw_TariffHistory cst on cst.ClientId = u.ClientId
    and cst.ProductType = 1
    and cst.IsLatest = 1
left join client.vw_TariffHistory clt on clt.ClientId = u.ClientId
    and clt.ProductType = 2
    and clt.IsLatest = 1
where (u.NewSt != '' or u.NewLT != '')
*/

drop table if exists #a
;

select *
into #a
from dbo.CustomListUsers cul
where cul.CustomlistID = 1080
    and not exists 
        (
            select 1 from prd.vw_product p
            where p.ClientId = cul.ClientId
                and p.Status in (2, 3, 4, 7)
        )
;

select ut.* -- update ut set IsLatest = 0
from #a c
inner join client.UserShortTermTariff ut on ut.ClientId = c.ClientId
    and ut.IsLatest = 1
where c.CustomField1 is not null
;

select ut.* -- update ut set IsLatest = 0
from #a c
inner join client.UserLongTermTariff ut on ut.ClientId = c.ClientId
    and ut.IsLatest = 1
where c.CustomField2 is not null
;

/*
insert client.UserShortTermTariff
(
    ClientId,TariffId,CreatedOn,CreatedBy,IsLatest
)
select
    c.ClientId
    ,c.CustomField1 as TariffId
    ,getdate() as CreatedOn
    ,cast(0x44 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
from #a c
where c.CustomField1 is not null
;

insert client.UserLongTermTariff
(
    ClientId,TariffId,CreatedOn,CreatedBy,IsLatest
)
select
    c.ClientId
    ,c.CustomField2 as TariffId
    ,getdate() as CreatedOn
    ,cast(0x44 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
from #a c
where c.CustomField2 is not null
*/
/


select * -- delete cul
from dbo.CustomListUsers cul
where cul.CustomlistID = 1080
    and not exists 
        (
            select 1 from #a
            where #a.ClientId = cul.ClientId
        )
;
/
select
    u.ClientId
    ,u.FirstName
    ,u.Lastname
    ,u.FatherName
    ,u.Phone
    ,u.Email
    ,stt.Name as NewStName
    ,stt.MaxAmount as NewStMaxAmount 
    ,stt.PercentPerDay as NewStPercentPerDay 
    ,ltt.Name as NewLtName
    ,ltt.MaxAmount as NewLtNameMaxAmount
    ,ltt.PercentPerDay as NewLtPercentPerDay
from dbo.br3321up1 u
inner join dbo.CustomListUsers cul on cul.ClientId = u.ClientId
    and cul.CustomlistID = 1080
left join prd.ShortTermTariff stt on stt.Name = replace(replace(u.NewSt, 'Silver\', ''), 'Start\', '')
left join prd.LongTermTariff ltt on ltt.Name = replace(u.NewLt, 'LimeUp\', '')
left join client.vw_TariffHistory cst on cst.ClientId = u.ClientId
    and cst.ProductType = 1
    and cst.IsLatest = 1
left join client.vw_TariffHistory clt on clt.ClientId = u.ClientId
    and clt.ProductType = 2
    and clt.IsLatest = 1
where (u.NewSt != '' or u.NewLT != '')
/

