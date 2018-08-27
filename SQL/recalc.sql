select
    pr.Productid
    ,pr.ContractNumber
    ,pr.PercentPerDay
    ,pr.StatusName
    ,pr.ProductTypeName
    ,pay.id as PaymentId
    ,pay.ProcessedOn
    ,prolong.CommandSnapshot as Prolong
    ,receiv.id as RegistrPay
    ,p.ConditionSnapshot
    , --update p set ConditionSnapshot = 
--    json_modify(pr.ConditionSnapshot, 'append $', 
--    json_modify(json_modify(json_modify(json_query(pr.ConditionSnapshot, '$[0]'), '$.PenaltyPercent', 0), '$.PercentPerDay', 0), '$.StartedOn', format(cast('20180722' as date), 'yyyy-MM-ddT00:00:00')))
    json_modify(pr.ConditionSnapshot, 'append $', 
    json_modify(json_query(pr.ConditionSnapshot, '$[0]'), '$.StartedOn', format(cast('20180829' as date), 'yyyy-MM-ddT00:00:00')))
from prd.vw_product pr
inner join prd.Product p on p.Id = pr.Productid
inner join pmt.Payment pay on pay.ContractNumber = pr.ContractNumber
    and pay.id in
    (
        1355388,1384256,1397783,1428101,1433464,1433466,1434251,1437348,1463652,1470006,1473762,1474934,1493846,1540865
    )
left join prd.OperationLog receiv on receiv.ProductId = pr.Productid
    and cast(receiv.OperationDate as date) = cast(pay.CreatedOn as date)
    and receiv.OperationId in (3, 13)
left join prd.OperationLog prolong on prolong.ProductId = pr.Productid
    and cast(prolong.OperationDate as date) = cast(pay.CreatedOn as date)
    and prolong.OperationId = 5
where pr.Productid = 435866
/

select * -- delete
from prd.OperationLog
where ProductId = 435866
    and cast(OperationDate as date) = '20180712'
    and id = 17876515


/

declare
    @num int = 3
    ,@from datetime = '20180722'
    ,@productid int = 435866
;

--insert prd.ShortTermProlongation
--(
--    CreatedOn,CreatedBy,Amount,StartedOn,Period,IsActive,ProductId,BuiltOn,Rate,Price
--)
select
    dateadd(second, 1, CreatedOn) as CreatedOn
    ,cast(0x44 as uniqueidentifier) as CreatedBy
    ,Amount
    ,StartedOn
    ,Period
    ,IsActive
    ,ProductId
    ,dateadd(second, 1, BuiltOn) as BuiltOn
    ,Rate
    ,Price
from
(
    select top (@num)
        dateadd(d, (row_number() over (order by id) - 1) * 14, @from) as StartedOn
        ,dateadd(d, (row_number() over (order by id) - 1) * 14 - 1, @from) as CreatedOn
        ,0 as Amount
        ,14 as Period
        ,1 as IsActive
        ,@productid as ProductId
        ,dateadd(d, (row_number() over (order by id) - 1) * 14 - 1, @from) as BuiltOn
        ,1.5 as Rate
        ,0 as Price
    from prd.product
) as v



/
--insert prd.OperationLog
--(
--    OperationDate,CommandType,CommandSnapshot,OperationId,ProductId,Suspended
--)
select
    CreatedOn as OperationDate
    ,'Prd.Domain.Commands.ProlongCommand, Prd.Domain, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null' as CommandType
    ,
    (
        select 
            Amount
            ,CreatedOn as OperationDate
            ,Period
            ,Price
            ,ProductId
            ,1 as ProductType
            ,Rate
            ,StartedOn
        from (select 1 a) b
        for json auto, without_array_wrapper
    ) as CommandSnapshot
    ,5 as OperationId
    ,stp.ProductId
    ,0 as Suspended
from prd.ShortTermProlongation stp
where stp.ProductId = 435866

/
select * --delete
from prd.OperationLog
where productid = 435866
    and OperationId = 5
order by id desc

select *
from prd.ShortTermProlongation
where ProductId = 435866


select * --delete
from prd.LongTermSchedule
where ProductId = 435866

select *-- delete
from prd.LongTermScheduleLog
where ProductId = 418789


select dateadd(d, 13, '20180818')


select *
from prd.Product
where id = 405258