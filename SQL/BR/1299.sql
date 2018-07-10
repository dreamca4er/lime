select
    count(*)
    ,count(isnull(stp.id, lcu.id))
from prd.vw_product p
outer apply
(
    select top 1 stp.id
    from prd.ShortTermProlongation stp
    where stp.ProductId = p.Productid
        and stp.IsActive = 1
) stp
outer apply
(
    select top 1 lcu.id
    from #tmp lcu
    where lcu.CreditId = p.Productid
) lcu
where cast(dateadd(d, p.Period, p.StartedOn) as date) between '20180101' and '20180531'
    and p.Status > 2
    
    
select
    lcu.id
    ,creditid
into #tmp
from "LIME-DB".Limezaim_Website.dbo.LongCreditUnits lcu
create index IX_tmp_creditid on #tmp(creditid)

-- Старый лайм
select 
    count(*)
    ,count(lcu.id)
from dbo.Credits c
outer apply
(
    select top 1 lcu.id
    from dbo.LongCreditUnits lcu
    where lcu.CreditId = c.Id
) lcu
where cast(dateadd(d, c.Period, c.DateStarted) as date) between '20170101' and '20170531'
    and c.Status not in (5, 8)
    
    /
    
    select top 109 *
    from dbo.migrateReg