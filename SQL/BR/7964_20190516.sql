declare
    @Date date = '20190413'
;

/*
drop table if exists #mm
;
*/
with p as 
(
    select 
        p.Productid
        , p.ClientId
        , p.StatusName
--        , b.Date as MissingDate
        , null as MissingDate
        , p.ScheduleCalculationTypeName
        , lts.*
        , ltsc.ScheduleSnapshot as CurrentScheduleSnapshot
    from prd.vw_product p
--    inner join dbo.br7964 b on b.ProductId = p.Productid
    outer apply
    (
        select top 1 
            ltsl.StartedOn as ScheduleStartedOn
            , lts.ScheduleSnapshot
        from prd.LongTermSchedule lts
        inner join prd.LongTermScheduleLog ltsl on ltsl.ScheduleId = lts.id
        where lts.ProductId = p.Productid
            and ltsl.StartedOn < @Date
        order by ltsl.StartedOn desc
    ) lts
    outer apply
    (
        select top 1 
            lts.ScheduleSnapshot
        from prd.LongTermSchedule lts
        inner join prd.LongTermScheduleLog ltsl on ltsl.ScheduleId = lts.id
        where lts.ProductId = p.Productid
        order by ltsl.StartedOn desc
    ) ltsc
    where p.ProductType = 2
        and p.Status in (3, 4, 7)
        and p.StartedOn <= '20190318'
)

/*
drop table if exists #mm
;

select
    mm.ProductId
    , mm.DateOperation
into #mm
from acc.vw_mm mm
where mm.ProductId in (select ProductId from p)
    and mm.ProductType = 2
    and mm.OperationTemplateId = 15
    and mm.accNumber like '48802%'
    and Date >= '20190301'
    and Date < '20190330'

create clustered index  IX_mm_ProductId_DateOperation on #mm(ProductId, DateOperation)
/

-- 663203 проценты переместились без проблем, хотя из меньше
select *
from p
where not exists
    (
        select *
        from #mm mm
        where mm.ProductId = p.ProductId
            and mm.DateOperation = p.MissingDate
    )
/

select *
from acc.vw_mm mm
where mm.ProductId = 671438--in (select ProductId from p)
    and mm.ProductType = 2
    and mm.accNumber like '48802%'
    and Date >= '20190401'
    and Date < '20190410'
/
*/
,j as 
(
    select
        p.Productid
        , p.ClientId
        , p.MissingDate
        , p.StatusName
        , p.ScheduleCalculationTypeName
        , p.CurrentScheduleSnapshot
        , js.*
    from p
    outer apply openjson(p.ScheduleSnapshot) with
    (
        Date date '$.Date'
        , Residue numeric(18, 2) '$.Residue'
    ) js
)

select
    j.ProductId
    , j.ClientId
    , j.StatusName
    , j.ScheduleCalculationTypeName
    , cbc.*
    , jlast.Date as LastPaymentDate
    , jlast.Residue as LastPaymentAmount
from j
outer apply
(
    select top 1
        cb.ActiveAmount * - 1 as ActiveAmount
    from bi.CreditBalance cb
    where cb.ProductId = j.ProductId
        and cb.InfoType = 'debt'
        and cb.DateOperation <= j.Date
    order by cb.DateOperation desc
) cbp
outer apply
(
    select top 1
        cast(cb.DateOperation as date) as DateOperation
        , (cb.ActiveAmount + cb.RestructAmount) * - 1 as ActiveAmount
        , (cb.OverdueAmount + cb.OverdueRestructAmount) * - 1 as OverdueAmount
        , cb.Commission * -1 as CommissionDebt
        , cb.Fine * -1 as FineDebt
    from bi.CreditBalance cb
    where cb.ProductId = j.ProductId
        and cb.InfoType = 'debt'
    order by cb.DateOperation desc
) cbc
outer apply
(
    select top 1 *
    from openjson(j.CurrentScheduleSnapshot) with
    (
        Date date '$.Date'
        , Residue numeric(18, 2) '$.Residue'
    ) js
    order by js.Date desc 
) jlast
where j.Date >= @Date
    and not exists
    (
        select 1 from j j2
        where j2.ProductId = j.ProductId
            and j2.Date >= @Date
            and j2.Date < j.Date
    )
    and cbp.ActiveAmount != j.Residue

