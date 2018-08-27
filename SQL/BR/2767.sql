drop table if exists #c
;

with c as 
(
    select
        c.clientid
        ,th.TariffName
        ,ltt.id as NewLT
        ,ltt.GroupName + '\' + ltt.Name as NewLTName
        ,ltt.MaxAmount
        ,ltt.PercentPerDay
    from client.vw_client c
    inner join client.vw_TariffHistory th on  th.ClientId = c.clientid
        and th.IsLatest = 1
        and th.ProductType = 1
        and th.TariffId >= 5
    inner join prd.LongTermTariff ltt on ltt.id = case 
                                            when th.TariffId in (5, 6) then 4
                                            when th.TariffId = 7 then 5
                                            when th.TariffId in (8, 9) then 6
                                            when th.TariffId = 10 then 7
                                            when th.TariffId in (11, 12) then 8
                                        end
    where c.IsFrauder = 0
        and c.IsDead = 0
        and c.IsCourtOrdered = 0
        and c.status = 2
        and not exists 
            (
                select 1 from prd.vw_product p
                where p.ClientId = c.clientid
                    and p.Status >= 2
            )
)

select *
into #c
from c
where not exists 
    (
        select 1 from client.vw_TariffHistory th
        where th.ClientId = c.ClientId
            and th.ProductType = 2
            and th.IsLatest = 1
            and th.TariffId > c.NewLT
    )
;

select * -- update th set islatest = 0
from #c c
inner join client.UserLongTermTariff th on th.ClientId = c.ClientId
    and th.IsLatest = 1
;
/*
insert client.UserLongTermTariff
(
    ClientId,TariffId,CreatedOn,CreatedBy,IsLatest    
)
select
    ClientId
    ,NewLT as TariffId
    ,getdate() as CreatedOn
    ,cast(0x44 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
from #c
;
*/
select
    c.clientid
    ,c.LastName
    ,c.FirstName
    ,c.FatherName
    ,c.Email
    ,c.PhoneNumber
    ,cl.NewLTName
    ,cl.MaxAmount
    ,cl.PercentPerDay
from #c cl
inner join client.vw_client c on cl.CLientId = c.CLientId



select top 10 *
from dbo.CustomListUsers

insert dbo.CustomListUsers
(
    CustomlistID   ,  ClientId   ,  DateCreated  ,   CustomField1
)
select
    1075
    ,CLientId
    ,cast(getdate() as date)
    ,NewLT
from #c