declare 
    @dateFrom date = '20171001'
    ,@dateTo date = '20171231'
;

select 
    oph.*
    ,gpb.*
    ,payments.*
from col.OverdueProductHistory oph
left join prd.ShortTermCredit stc on stc.Id = oph.ProductId
left join prd.LongTermCredit ltc on ltc.Id = oph.ProductId
outer apply
(
    select top 1
        case 
            when ltc.id is not null
            then gpb.debtAmntOver   
            else coalesce(nullif(gpb.debtAmntOver, 0), gpb.debtAmntCurrAndRestr)
        end as debtAmntOver
        ,gpb.debtPercOver
        ,gpb.debtFine
        ,gpb.debtComission
    from acc.getProdBal(0, 0) gpb
    where gpb.productid = oph.ProductId
        and (gpb.date < (select min(dt)
                        from (values (cast(oph.Enddate as date)), (cast(getdate() as date))) a (dt))
            and (cast(oph.StartDate as date) != cast(oph.EndDate as date) or cast(oph.EndDate as date) is null)
                or gpb.date = cast(oph.StartDate as date))
        and gpb.debtAmnt != 0
    order by gpb.date desc
) gpb
outer apply
(
    select top 1
        sum(gp.paidAmnt) as paidAmnt
        ,sum(gp.paidPerc) as paidPerc
        ,sum(gp.paidProlong) as paidProlong
        ,sum(gp.paidComission) as paidComission
        ,sum(gp.paidFine) as paidFine
    from acc.getProdBal(0, 0) gp
    where gp.productid = oph.ProductId
        and dateadd(s, 86399, gp.date) >= cast(oph.StartDate as date)
        and (dateadd(s, 86399, gp.date) <= cast(oph.Enddate as date) or oph.Enddate is null)
        and gp.date >= @dateFrom
        and gp.date <= @dateTo
) payments 
where productid in (275933, 999001, 999002, 999003)
    and oph.StartDate <= @dateTo
    and (oph.EndDate is null or oph.EndDate >= @dateFrom)
order by startdate


/

select top 10 *
from col.OverdueProductHistory oph
where productid = 275933
/

