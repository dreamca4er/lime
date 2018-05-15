drop table if exists #clientinfo
;

select 
    c.clientid
    ,case when th.HasTariff > 0 then 203 else 202 end as Substatus
    ,pr.*
into #clientinfo
from client.vw_client c
inner join client.UserStatusHistory ush on ush.ClientId = c.clientid
    and ush.IsLatest = 1
outer apply
(
	select top 1
		p.productid
		,p.statusName
		,p.datePaid
	from prd.vw_Product p
	where p.clientid = c.clientid 
		and p.status != 1
	order by p.productid desc
) pr
outer apply
(
    select count(*) as HasTariff
    from client.vw_TariffHistory th
    where th.ClientId = c.clientid
        and th.IsLatest = 1
) th
where (c.substatus = 204 or ush.Substatus = 204)
    and not exists 
                (
                    select 1
                    from prd.vw_product p
                    where p.clientId = c.clientid
                        and p.status in (0,2,3,4,7)
                )

select *
from #clientinfo


update c 
set 
    c.status = 2
    ,c.substatus = ci.substatus
from client.Client c
inner join #clientinfo ci on ci.clientid = c.id

;

update ush set islatest = 0
from [Client].[UserStatusHistory] ush
where clientid in (select clientid from #clientinfo)
;

insert into [Client].[UserStatusHistory]
(
clientid, status, substatus, islatest, createdon, createdby
)
select 
	clientid
	,2
	,substatus
	,1
	,datePaid
	,cast(0x0 as uniqueidentifier)
from #clientinfo
