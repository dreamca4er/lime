drop table if exists #client
;

with c as 
(
    select
        c.id as ClientId
        ,LastProduct.DatePaid as LastCreditDatePaid
        ,LastStatus.LastStatusDate
        ,case isnull(ustt.Id, ultt.Id) / isnull(ustt.Id, ultt.Id)
            when 1 then 203
            else 202
        end as NewSubstatus
    from client.Client c
    left join client.UserShortTermTariff ustt on ustt.ClientId = c.id
        and ustt.IsLatest = 1
    left join client.UserShortTermTariff ultt on ultt.ClientId = c.id
        and ultt.IsLatest = 1
    outer apply
    (
        select max(p.DatePaid) as DatePaid
        from prd.vw_product p
        where p.ClientId = c.id
            and p.Status = 5
    ) as LastProduct
    outer apply
    (
        select ush.CreatedOn as LastStatusDate
        from client.UserStatusHistory ush
        where ush.ClientId = c.id
            and ush.IsLatest = 1
    ) as LastStatus
    where Substatus = 204
        and not exists 
            (
                select 1 from prd.vw_product p
                where p.ClientId = c.id
                    and p.Status in (0, 2, 3, 4, 7)
            )
        and exists 
            (
                select 1 from prd.vw_product p
                where p.ClientId = c.id
                    and p.Status = 5
            )
)

select *
into #client
from c
;
/
select c.id, c.Substatus
--update c set Substatus = cl.NewSubstatus
from #client cl
inner join Client.Client c on c.id = cl.ClientId
;

select ush.*
--update ush set IsLatest = 0
from #client cl
inner join client.UserStatusHistory ush on ush.ClientId = cl.ClientId
where ush.IsLatest = 1
;
/*
insert client.UserStatusHistory
(
    ClientId,Status,IsLatest,CreatedOn,CreatedBy,BlockingPeriod,Substatus
)
select
    cl.ClientId
    ,2 as Status
    ,1 as IsLatest
    ,LastCreditDatePaid as CreatedOn
    ,cast(0x0 as uniqueidentifier) as CreatedBy
    ,0 as BlockingPeriod
    ,cl.NewSubstatus as Substatus
from #client cl
*/