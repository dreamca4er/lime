drop table if exists #mnth
;

select distinct
    dateadd(d, 1, eomonth(dt1, -1)) as M
    ,eomonth(dt1) as M2
into #mnth
from bi.tf_gendate('20180101', '20181203')
;

drop table if exists #sl
;

select
    sl.ProductId
    ,sl.Status
    ,sl.StartedOn
    ,eomonth(sl.StartedOn) as M2
into #sl
from prd.vw_statusLog sl
;

create index IX_sl_ProductId_StartedOn on #sl(ProductId, StartedOn)
;

drop table if exists #op
;

with sl as 
(
    select
        mnth.*
        ,sl.Status
        ,sl.StartedOn
        ,sl.ProductId
    from #mnth mnth
    outer apply
    (
        select
            sl.ProductId
            ,sl.Status
            ,sl.StartedOn
        from #sl sl
        where sl.StartedOn < mnth.M2
            and not exists 
                (
                    select 1 from #sl sl2
                    where sl2.ProductId = sl.ProductId
                        and sl2.StartedOn > sl.StartedOn
                        and cast(sl2.StartedOn as date) <= mnth.M2
                )
    ) sl
    where sl.Status = 4
        and 90 between datediff(d, sl.StartedOn, mnth.M) and datediff(d, sl.StartedOn, mnth.M2)  
)

select
    sl.M
    ,sl.M2
    ,count(*) as NewOverdue90
into #op
from sl
inner join prd.ShortTermCredit stp on stp.id = sl.productid
group by sl.M,sl.M2
/

select *
from #op op
outer apply
(
    select count(*) as Started
    from prd.vw_product p
    where cast(p.StartedOn as date) between op.M and op.M2
        and p.Status > 2
        and p.ProductType = 1
) st
outer apply
(
    select count(*) as Repaid
    from prd.vw_product p
    where cast(p.DatePaid as date) between op.M and op.M2
        and p.Status > 2
        and p.ProductType = 1
) dp
