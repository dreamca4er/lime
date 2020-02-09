/*
declare
    @Workers int = 1
    , @PackSize int = 100
    , @CheckSuspended bit = 1
    , @CurrentDate date = cast(getdate() as date)
;
*/
with prod as
(
    select
        p.id as ProductId
        , ol.OperationDate
        , lod.LastOperDate
        , nc.NeedsCalc
    from prd.Product p
    inner join prd.ShortTermCredit stc on stc.id = p.id
    outer apply
    (
        select top 1 1 as HasAccInfo
        from acc.TransactionInfo ti
        where ti.ProductId = p.id
    ) ti
    outer apply
    (
        select ac.State
        from acccore.Account ac
        where ac.EntityId = p.id
            and ac.Purpose = 'Amount'
    ) ac
    outer apply
    (
        select top 1 ol2.OperationDate as LastOperDate
        from prd.OperationLog ol2
        where ol2.ProductId = p.id
            and ol2.OperationId = 4
        order by ol2.OperationDate desc
    ) lod
    outer apply
    (
        select
            case
                when stc.Status = 5 and ac.State != 2
                then 'Repaid'
                when stc.Status = 5
                then null
                when lod.LastOperDate is null
                then 'Not calculated'
                when cast(lod.LastOperDate as date) < cast(@CurrentDate as date)
                then 'Partially calculated'
            end as NeedsCalc
    ) nc
    left join prd.OperationLog ol on ol.ProductId = p.id
        and ol.OperationId = 2
    where 1=1
        and 0=0
        and ol.OperationDate is not null
        and stc.Status not in (1, 2)
        and (p.StartedOn < cast(@CurrentDate as date) or p.StartedOn is null)
        and
        (
            p.CalcStatus = 0 and @CheckSuspended = 1
            or
            p.CalcStatus != 2 and @CheckSuspended = 0
        )
        and
        (
            not exists
            (
                select 1 from prd.OperationLog ol
                where ol.ProductId = p.id
                    and ol.Suspended = 1
            )
            and @CheckSuspended = 1
            or @CheckSuspended = 0
        )
)

,num as
(
    select
        p.ProductId
        , od.OperationDate
        , NeedsCalc
        , dense_rank() over (order by od.OperationDate) as WorkerNum
        , row_number() over (partition by od.OperationDate order by p.ProductId) as ProductNum
    from prod p
    outer apply
    (
        select
            case
                when NeedsCalc in ('Repaid', 'Not calculated')
                then OperationDate
                when NeedsCalc = 'Partially calculated'
                then dateadd(s, -1, LastOperDate)
                else OperationDate
            end as OperationDate
    ) od
    where NeedsCalc is not null
)

select
    ProductId
    , OperationDate
--    , NeedsCalc
from num
where ProductNum <= @PackSize
    and WorkerNum <= @Workers
    and @CheckSuspended = 1
    or @CheckSuspended = 0