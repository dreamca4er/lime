drop table if exists #NewCommers
;

drop table if exists #OldCollection
;

drop table if exists #Changes
;

drop table if exists dbo.OverdueProductBack
;

select *
into dbo.OverdueProductBack
from col.OverdueProduct
;

select
    op.id
    ,op.ProductId
    ,op.OverdueDays
    ,op.Amount
    ,op.CollectorId
    ,row_number() over (partition by op.CollectorId order by id desc) as num
    ,count(*) over (partition by op.CollectorId) as cnt
into #NewCommers
from col.overdueproduct op
where id not in 
    (
        select
            op.id
        from col.overdueproduct op
        outer apply
        (
            select top 1 ii.*
            from col.InternalInteraction ii
            where ii.ProductId = op.ProductId
            order by ii.DatePromises desc
        ) ii
        where op.IsDeleted = 0
            and op.CollectorId in
            (
                '81D0FFAD-48F7-4AED-9001-4D6329140143'
                ,'402FB7B0-840D-4DC8-8CA6-52E5B5E93D19'
                ,'8B519714-0408-4530-B31B-3A185537FD00'
            )
            and ii.Callstatus = 2
    )
    and op.Fixed = 0
    and op.IsProcessed = 0
    and op.IsDeleted = 0
    and op.CollectorId in
    (
        '81D0FFAD-48F7-4AED-9001-4D6329140143'
        ,'402FB7B0-840D-4DC8-8CA6-52E5B5E93D19'
        ,'8B519714-0408-4530-B31B-3A185537FD00'
    )
;

select
    op.id
    ,op.ProductId
    ,op.OverdueDays
    ,op.Amount
    ,op.CollectorId
into #OldCollection
from col.overdueproduct op
inner join col.CollectorGroup cg on cg.CollectorId = op.CollectorId
outer apply
(
    select top 1 ii.*
    from col.InternalInteraction ii
    where ii.ProductId = op.ProductId
    order by ii.DatePromises desc
) ii
where op.IsDeleted = 0
    and op.CollectorId not in
    (
        '81D0FFAD-48F7-4AED-9001-4D6329140143'
        ,'402FB7B0-840D-4DC8-8CA6-52E5B5E93D19'
        ,'8B519714-0408-4530-B31B-3A185537FD00'
    )
    and (ii.Callstatus != 2 or ii.Callstatus is null)
    and cg.Name = 'B'
    and op.OverdueDays > 8
    and op.OverdueDays < 38
    and op.Fixed = 0
    and op.IsProcessed = 0
;

select
    n.id as NewCollectorid
    ,n.ProductId as NewCollectorProductId
    ,n.OverdueDays as NewCollectorOverdueDays
    ,n.Amount as NewCollectorAmount
    ,n.CollectorId as NewCollectorCollectorId
    ,o.id as OldCollectorid
    ,o.ProductId as OldCollectorProductId
    ,o.OverdueDays as OldCollectorOverdueDays
    ,o.Amount as OldCollectorAmount
    ,o.CollectorId as OldCollectorCollectorId
into #Changes
from #NewCommers n
cross apply
(
    select top 1
        o.*
    from #OldCollection o
    where abs(o.Amount - n.Amount) < 1000
        and o.OverdueDays != n.OverdueDays
        and o.productid < n.productid
    order by newid()
) o
where n.num < n.cnt * 0.85
;

delete
from #Changes
where OldCollectorProductId in
    (
        select OldCollectorProductId
        from #Changes c
        group by OldCollectorProductId
        having count(*) != 1
    )
;

update op set op.isdeleted = 1
from #Changes c
inner join col.OverdueProduct op on op.Id = c.OldCollectorid

update op set op.isdeleted = 1
from #Changes c
inner join col.OverdueProduct op on op.Id = c.NewCollectorid

select 
insert Col.OverdueProduct
(
    ProductId      -- Из старой записи
    ,ProductType    -- Из старой записи
    ,Amount         -- Из старой записи
    ,IsProcessed    -- 0
    ,CreatedOn      -- getdate()
    ,CreatedBy      -- 0x44
    ,Date           -- getdate()
    ,Fixed          -- 0
    ,OverdueDays    -- Из старой записи
    ,Number         -- Из старой записи
    ,CheckoutDate   -- dateadd(d, 1, getdate())
    ,IsDeleted      -- 0
    ,AssignedDays   -- 0
    ,CollectorId    -- neededCollectorId
)
select
    op.ProductId      -- Из старой записи
    ,op.ProductType    -- Из старой записи
    ,op.Amount         -- Из старой записи
    ,0    -- 0
    ,getdate()      -- getdate()
    ,cast(0x44 as uniqueidentifier)      -- 0x44
    ,getdate()           -- getdate()
    ,0          -- 0
    ,op.OverdueDays    -- Из старой записи
    ,op.Number         -- Из старой записи
    ,dateadd(d, 1, getdate())   -- dateadd(d, 1, getdate())
    ,0      -- 0
    ,0   -- 0
    ,c.NewCollectorCollectorId    -- neededCollectorId
from #Changes c
inner join col.OverdueProduct op on op.Id = c.OldCollectorid

insert Col.OverdueProduct
(
    ProductId      -- Из старой записи
    ,ProductType    -- Из старой записи
    ,Amount         -- Из старой записи
    ,IsProcessed    -- 0
    ,CreatedOn      -- getdate()
    ,CreatedBy      -- 0x44
    ,Date           -- getdate()
    ,Fixed          -- 0
    ,OverdueDays    -- Из старой записи
    ,Number         -- Из старой записи
    ,CheckoutDate   -- dateadd(d, 1, getdate())
    ,IsDeleted      -- 0
    ,AssignedDays   -- 0
    ,CollectorId    -- neededCollectorId
)
select
    op.ProductId      -- Из старой записи
    ,op.ProductType    -- Из старой записи
    ,op.Amount         -- Из старой записи
    ,0    -- 0
    ,getdate()      -- getdate()
    ,cast(0x44 as uniqueidentifier)      -- 0x44
    ,getdate()           -- getdate()
    ,0          -- 0
    ,op.OverdueDays    -- Из старой записи
    ,op.Number         -- Из старой записи
    ,dateadd(d, 1, getdate())   -- dateadd(d, 1, getdate())
    ,0      -- 0
    ,0   -- 0
    ,c.OldCollectorCollectorId    -- neededCollectorId
from #Changes c
inner join col.OverdueProduct op on op.Id = c.NewCollectorid