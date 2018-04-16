declare @parameters nvarchar(max) = 
/*
AddLTtoST       Даем ли Кзшникам с последники тарифами КЗ еще и ДЗ
AddStep         Сколько шагов добавляем
ProductType     Какие типы продуктов берем
StepsToExclude  На какие шаги не повышаем
*/
    '
    {
        "AddLTtoST": 1, 
        "AddStep": 2,
        "ProductType": [
            1, 2
        ],
        "StepsToExclude": [
            "LimeUp_LimeUp9"
        ]
    }
    '
    ,@AddLTtoST bit
    ,@AddStep int
    ,@ProductType nvarchar(max)
    ,@StepsToExclude nvarchar(max)

set @AddLTtoST =  cast(json_value(@parameters, '$.AddLTtoST') as bit)
set @AddStep = json_value(@parameters, '$.AddStep')
set @ProductType = json_query(@parameters, '$.ProductType')
set @StepsToExclude = json_query(@parameters, '$.StepsToExclude') 
;

drop table if exists #t
;

drop table if exists #c
;
-----------------------------------------------------------------
-- Генерим нужные нам тарифы и их повышенную версию
-----------------------------------------------------------------
with t as 
(
    select
        id
        ,1 as ProductType
        ,SortOrder
        ,GroupName + '_' + Name as Tariff
    from prd.ShortTermTariff
    
    union
    
    select
        id
        ,2 as ProductType
        ,SortOrder
        ,GroupName + '_' + Name as Tariff
    from prd.LongTermTariff
)

,tNum as 
(
    select *
        ,row_number() over (order by ProductType, SortOrder) as RealOrder
        ,row_number() over (partition by ProductType order by SortOrder) as RealOrderProduct 
    from t
)

select
    t.id as OldTariffId
    ,t.ProductType as OldProductType
    ,t.Tariff as OldTariff
    ,t1.id as NewTariffId
    ,t1.ProductType as NewProductType
    ,t1.Tariff as NewTariff
into #t
from tNum t
inner join tNum t1 on @AddLTtoST = 1
    and
    (
        t1.RealOrder = 
                    (
                        select max(t2.RealOrder) 
                        from tNum t2 
                        where t2.RealOrder <= t.RealOrder + @AddStep 
                            and t2.Tariff not in (select value from openjson(@StepsToExclude))
                    )
    )
    or @AddLTtoST = 0
    and t.ProductType = t1.ProductType
    and
    (
        t1.RealOrderProduct = 
                    (
                        select max(t2.RealOrderProduct) 
                        from tNum t2 
                        where t2.RealOrderProduct <= t.RealOrderProduct + @AddStep 
                            and t2.Tariff not in (select value from openjson(@StepsToExclude))
                    )
    )    
where t1.Tariff not in (select value from openjson(@StepsToExclude))
    and t.Tariff not in (select value from openjson(@StepsToExclude))
    and t1.Tariff != t.Tariff
    and t.ProductType in (select value from openjson(@ProductType))
;

-----------------------------------------------------------------
-- Выбираем нужных клиентов
-----------------------------------------------------------------
with up as 
(
    select
        th.id as UserTariffHistoryId
        ,th.ClientId
        ,th.ProductType
        ,th.TariffId
        ,th.TariffName
        ,t.NewProductType
        ,t.NewTariffId
        ,count(case when th.ProductType != t.NewProductType then 1 end) over (partition by th.ClientId) as HasProductTypeUpdate
        ,count(case when th.ProductType = 2 then 1 end) over (partition by th.ClientId) as HasLT
        ,count(case when th.ProductType = 1 then 1 end) over (partition by th.ClientId) as HasST
    from client.vw_TariffHistory th
    inner join #t t on t.OldTariffId = th.TariffId
        and t.OldProductType = th.ProductType
    where th.IsLatest = 1
        and not exists
                (
                    select 1 from prd.vw_product p
                    where th.ClientId = p.ClientId
                        and p.status in (3, 4, 7)
                )
)

select *
    ,case
        when HasLT = 0 and HasProductTypeUpdate > 0 then 1
        when HasLT = 0 and HasST > 0 then 2
        when HasLT > 0 and HasST = 0 then 3
        when HasLT > 0 and HasST > 0 and HasProductTypeUpdate = 0 then 4
        when HasLT > 0 and HasProductTypeUpdate > 0 then 5
    end as UpType
into #c
from up
;

/
-----------------------------------------------------------------
-- Для каждого типа клиента совершаем нужные манипуляции
-----------------------------------------------------------------

-----------------------------------------------------------------
--1 Обновление КЗ
-----------------------------------------------------------------

select
    c.* -- update ustt set IsLatest = 0
from #c c
inner join client.UserShortTermTariff ustt on ustt.Id = c.UserTariffHistoryId
where c.UpType in (1, 5)
    and c.ProductType = 1
;

--insert into client.UserShortTermTariff(ClientId, TariffId, CreatedOn, CreatedBy, IsLatest)
select
    c.ClientId
    ,c.TariffId
    ,getdate()
    ,cast(0x44 as uniqueidentifier)
    ,1
from #c c
where c.UpType in (1, 5)
    and c.ProductType = 1
;

-----------------------------------------------------------------
--2 Выдача ДЗ
-----------------------------------------------------------------

-- insert into client.UserLongTermTariff (ClientId, TariffId, CreatedOn, CreatedBy, IsLatest)
select
    c.ClientId
    ,c.NewTariffId
    ,getdate()
    ,cast(0x44 as uniqueidentifier)
    ,1
from #c c
where c.UpType = 1
    and c.ProductType = 1

-----------------------------------------------------------------
--3 Повышение КЗ
-----------------------------------------------------------------

select
    c.* -- update ustt set IsLatest = 0
from #c c
inner join client.UserShortTermTariff ustt on ustt.Id = c.UserTariffHistoryId
where c.UpType in (2, 4)
    and c.ProductType = 1
;

--insert into client.UserShortTermTariff(ClientId, TariffId, CreatedOn, CreatedBy, IsLatest)
select
    c.ClientId
    ,c.NewTariffId
    ,getdate()
    ,cast(0x44 as uniqueidentifier)
    ,1
from #c c
where c.UpType in (2, 4)
    and c.ProductType = 1
;

-----------------------------------------------------------------
-- 4 Повышение ДЗ
-----------------------------------------------------------------

select
    c.* -- update ultt set IsLatest = 0
from #c c
inner join client.UserLongTermTariff ultt on ultt.Id = c.UserTariffHistoryId
where c.UpType in (3, 4, 5)
    and c.ProductType = 2
;

-- insert into client.UserLongTermTariff (ClientId, TariffId, CreatedOn, CreatedBy, IsLatest)
select
    c.ClientId
    ,c.NewTariffId
    ,getdate()
    ,cast(0x44 as uniqueidentifier)
    ,1
from #c c
where c.UpType in (3, 4, 5)
    and c.ProductType = 2
-----------------------------------------------------------------
/

select 
    cl.clientid
    ,cl.substatusName
    ,cl.fio
    ,cl.PhoneNumber
    ,cl.Email
    ,t.NewTariff
    ,isnull(stt.MaxAmount, ltt.MaxAmount) as MaxAmount
from #c c
inner join #t t on t.NewTariffId = c.NewTariffId
    and c.NewProductType = t.NewProductType
left join prd.ShortTermTariff stt on stt.id = t.NewTariffId
    and t.NewProductType = 1
left join prd.longTermTariff ltt on ltt.id = t.NewTariffId
    and t.NewProductType = 2
inner join client.vw_Client cl on cl.clientid = c.clientid
where cl.Status = 2
    and (UpType = 5 and c.ProductType = 2 or UpType != 5) 
;

select *
into dbo.tb359
from #c