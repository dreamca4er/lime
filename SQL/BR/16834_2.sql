--select *
--INTO #TMP
--from 
--(
--select ProductId from Stuff.dbo.br16834_2
--union all
--select ProductId from Stuff.dbo.br16834
--) a
/*
drop table if exists #overdue;
create table #overdue (CrType int, MinD int, MaxD int, Pct tinyint, Name nvarchar(10));

insert #overdue
select *
from (values (1,1,30,50, '001–30')
    , (1, 31,  60, 80, '031–60')
    , (1, 61,  90, 90, '061–90')
    , (1, 91, 120,100, '091–120')
    , (1,121, 180,100, '121–180')
    , (1,181, 270,100, '181–270')
    , (1,271, 360,100, '271–360')
    , (1,361,9999,100, '360+')
    , (2,  1,  30,  3, '001–30')
    , (2, 31,  60, 10, '031–60')
    , (2, 61,  90, 20, '061–90')
    , (2, 91, 120, 40, '091–120')
    , (2,121, 180, 50, '121–180')
    , (2,181, 270, 65, '181–270')
    , (2,271, 360, 80, '271–360')
    , (2,361,9999,100, '360+')
    ) as x(CrType, MinD, MaxD, Pct, Name)
;
*/
declare
    @DateNext datetime2 = '20191227'
;

drop table if exists #inf
;
with d as 
(
    select
        N'банкрот' as Reason
        , c.clientid
        , c.fio
        , p.ProductId
        , p.ContractNumber
        , cast(p.CreatedOn as date) as ContractDate
        , cast(p.StartedOn as date) as StartedOn
        , p.Amount
        , p.Period
        , os.OverdueStartedOn
        , wo.*
    from #TMP b
    inner join prd.vw_Product p on p.Productid = b.Productid
    inner join client.vw_client c on c.clientid = p.ClientId
    outer apply
    (
        select top 1 cast(sl.StartedOn as date) as OverdueStartedOn
        from prd.vw_statusLog sl
        where sl.ProductId = p.Productid
            and sl.Status = 4
        order by sl.StartedOn desc
    ) os
    outer apply
    (
        select
            sum(iif(sj.SumType / 1000 = 1, RawSum, 0)) as AmountWrittenOff
            , sum(iif(sj.SumType / 1000 = 2, RawSum, 0)) as PercentWrittenOff
            , sum(iif(sj.SumType = 4011, RawSum, 0)) as CommissionWrittenOff
            , sum(iif(sj.SumType = 3021, RawSum, 0)) as PenaltyWrittenOff
        from acc.ProductSumJournal sj
        where sj.ProductId = p.Productid
            and sj.ProductType = p.ProductType
            and sj.ChangeType = 10
    ) wo
    where p.Status = 8
)

select
    p.*
    , st.*
    , 4 as StatusOnEndPeriod
    , case when isnull(cor.Amount, p.Amount) > 30000 or p.Period > 30 then 2 else 1 end TypeFlag-- 2 LongTerm, 1 - ShortTerm
into #inf
from d p
left join bi.vw_ProductManualCorrected cor on cor.ProductId = p.ProductId
outer apply (
    select top 1 ss.StartedOn as StatusStartedOnEndPeriod
    from prd.vw_statusLog ss
    where ss.ProductId = p.Productid
        and ss.StartedOn < @DateNext
    order by ss.StartedOn desc
) st
/
declare
    @DateNext datetime2 = '20191227'
;

drop table if exists #rsrv

select 
    q.ProductId
    , iif(q.StatusOnEndPeriod = 4, datediff(day, q.StatusStartedOnEndPeriod, @DateNext), null) as OverdueDays
    , case
        when q.StatusOnEndPeriod = 7 and q.TypeFlag = 1 then 20
        when q.StatusOnEndPeriod = 7 and q.TypeFlag = 2 then 5
        else o.Pct
    end as Pct
    , case  
        when q.StatusOnEndPeriod = 7 then N'Рестр'
        when q.StatusOnEndPeriod = 4 then o.Name
        else N'-'
    end as ReserveName
    , cast(q.StatusStartedOnEndPeriod as date) as StsDate
into #rsrv
from #inf q
left join #overdue o on o.CrType = q.TypeFlag
    and case when q.StatusOnEndPeriod = 4 then datediff(day, q.StatusStartedOnEndPeriod, @DateNext) end between o.MinD and o.MaxD
;
/

select
    p.*
    , isnull(round(AmountWrittenOff * r.Pct / 100.0, 2), 0) as ReserveAmt2712
    , isnull(round(PercentWrittenOff * r.Pct / 100.0, 2), 0) as ReservePct2712
    , isnull(round(CommissionWrittenOff * r.Pct / 100.0, 2), 0) as ReserveCom2712
    , cb3011.*
from #inf p
left join #rsrv r on r.Productid = p.Productid
outer apply
(
    select top 1
        cb.TotalAmount * -1 as AmountDebt3011
        , cb.TotalPercent * -1 as PercentDebt3011
        , cb.Fine * -1 as FineDebt3011
        , cb.Commission * -1 as CommissionDebt3011
    from bi.CreditBalance cb
    where cb.ProductId = p.ProductId
        and cb.InfoType = 'debt'
        and cb.DateOperation <= '20191130'
    order by cb.DateOperation desc
) cb3011