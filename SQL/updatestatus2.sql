drop table if exists #cl
;

select 
    c.clientid
    ,prd.DatePaid as StatusDate
    ,case 
        when th.tc > 0 then 203
        else 202
    end as SubStatus
into #cl
from client.vw_client c
cross apply
(
    select top 1 p.DatePaid
    from prd.vw_Product p
    where p.ClientId = c.clientid
        and cast(p.DatePaid as date) = '20180719'
    order by p.Productid desc 
) prd
outer apply
(
    select count(*) as tc
    from client.vw_TariffHistory th
    where th.ClientId = c.clientid
        and th.IsLatest = 1
) th
where Substatus = 204
    and exists 
        (
            select 1 from prd.vw_product p
            where p.ClientId = c.ClientId
                and cast(p.DatePaid as date) = '20180719'
        )
    and not exists 
        (
            select 1 from prd.vw_product p
            where p.ClientId = c.clientid
                and p.Status in (3,4,7)
        )
;


select ush.* --update ush set islatest = 0
from client.UserStatusHistory ush
inner join #cl on #cl.ClientId = ush.ClientId
where ush.IsLatest = 1
;

insert client.UserStatusHistory 
(
    ClientId,Status,IsLatest,CreatedOn,CreatedBy,BlockingPeriod,Substatus
)
select
    clientid
    ,2
    ,1
    ,StatusDate
    ,cast(0x0 as uniqueidentifier)
    ,0
    ,SubStatus
from #cl

select * -- update c set c.substatus = #cl.substatus 
from #cl
inner join client.Client c on #cl.clientid = c.id