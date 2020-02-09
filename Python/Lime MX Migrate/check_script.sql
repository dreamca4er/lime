/*
declare
    @Workers int = 1
    , @PackSize int = 100
    , @CheckSuspended bit = 1
    , @CurrentDate date = cast(getdate() as date)
;
*/
with a as
(
    select
        prod.Productid
        , ol.OperationDate
        , dense_rank() over (order by ol.OperationDate) as WorkerNum
        , row_number() over (partition by ol.OperationDate order by ol.ProductId) as ProductNum
    from prd.vw_product prod
    inner join prd.Product p on p.Id = prod.Productid
    inner join stage.dbo.ProductsToCalc ptc on ptc.Productid = prod.Productid
    inner join prd.OperationLog ol on ol.ProductId = prod.Productid
        and ol.CommandType = 'Prd.Domain.Commands.MoneySentCommand, Prd.Domain, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null'
    where 1=1
        and 0=0
        and prod.ProductType = 2
--        and prod.Status = 5
        and not exists
        (
            select 1 from acc.vw_acc aa
            where aa.ProductId = prod.Productid
                and aa.ProductType = prod.ProductType
                and aa.Number like '48801%'
                and aa.DateClose is not null
        )
        and
        (
            prod.CalcStatus = 0 and @CheckSuspended = 1
            or
            prod.CalcStatus != 2 and @CheckSuspended = 0
        )
        and
        (
            not exists
            (
                select 1 from prd.OperationLog ol
                where ol.ProductId = prod.ProductId
                    and ol.Suspended = 1
            )
            and @CheckSuspended = 1
            or @CheckSuspended = 0
        )
)

select *
from a
where ProductNum <= @PackSize
    and WorkerNum <= @Workers
    and @CheckSuspended = 1
    or @CheckSuspended = 0