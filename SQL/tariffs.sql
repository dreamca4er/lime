drop table if exists #tmp
;

drop table if exists #tmp2
;

select
    uth.clientId
    ,uth.TariffID
    ,uth.CreatedOn
    ,uth.userid as Verifier
    ,case when uth.TariffID = 4 then 2 else 1 end as ProductType
    ,row_number() over (partition by uth.clientId, uth.CreatedOn, case when uth.TariffID = 4 then 2 else 1 end order by uth.StepOrder) as rn
into #tmp
from dbo.migrateUserTariff uth   

create clustered index IX_tmp_clientId_CreatedOn_ProductType_rn on #tmp(clientId, CreatedOn, ProductType, rn)

select
    id
    ,ClientId
    ,ProductType
    ,CreatedOn
    ,TariffId
    ,CreatedBy as Verifier
    ,row_number() over (partition by th.ClientId, th.CreatedOn, ProductType order by th.TariffId) as rn
into #tmp2
from client.vw_TariffHistory th
where CreatedOn <= '2018-02-27 05:52:24.050' 
;

create clustered index IX_tmp2_clientId_CreatedOn_ProductType_rn on #tmp2(clientId, CreatedOn, ProductType, rn)
;
/
drop table if exists #tmp3
;

select 
    coalesce(a.id, case 
                    when t.clientId = t.Verifier then cast(0x11 as uniqueidentifier)
                    else cast(0x00 as uniqueidentifier)
                    end) as CreatedBy
    ,t2.id
    ,t.producttype
into #tmp3
from #tmp t
inner join #tmp2 t2 on t.clientId = t2.clientId
    and t.CreatedOn = t2.CreatedOn
    and t.ProductType = t2.ProductType
    and t.rn = t2.rn
outer apply
(
    select top 1 
        u.adminid
        ,u.loginname
    from sts.oldusers u
    where u.adminid = t.Verifier
) u
left join sts.vw_admins a on a.username = u.loginname

create index IX_tmp3_producttype_id on #tmp3(producttype, id)

/
select count(case when st.CreatedBy != t.CreatedBy and lt.CreatedBy != t.CreatedBy then 1 end)-- update lt set lt.CreatedBy = t.CreatedBy 
from #tmp3 t
left join client.UserShortTermTariff st on t.producttype = 1 
    and t.id = st.id
left join client.UserLongTermTariff lt on t.producttype = 2
    and t.id = lt.id



