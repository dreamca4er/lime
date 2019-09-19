drop table if exists #Del
;

select
    dateadd(hour, datepart(hour, ush.CreatedOn), cast(cast(ush.CreatedOn as date) as datetime2)) as Date
    , count(*) as DeletedCount
    , cast('1. Lime' as nvarchar(10)) as Project
into #Del
from client.UserStatusHistory ush 
where ush.Status = 4
    and ush.CreatedBy = 0x3693
    and ush.CreatedOn >= '2019-07-29 09:00:00.000'
group by dateadd(hour, datepart(hour, ush.CreatedOn), cast(cast(ush.CreatedOn as date) as datetime2))
;

insert #Del
select
    dateadd(hour, datepart(hour, ush.CreatedOn), cast(cast(ush.CreatedOn as date) as datetime2)) as Date
    , count(*) as DeletedCount
    , '2. Konga'
from "BOR-MANGO-DB".Borneo.client.UserStatusHistory ush 
where ush.Status = 4
    and ush.CreatedBy = 0x3693
    and ush.CreatedOn >= '2019-07-29 09:00:00.000'
group by dateadd(hour, datepart(hour, ush.CreatedOn), cast(cast(ush.CreatedOn as date) as datetime2))
;

insert #Del
select
    dateadd(hour, datepart(hour, ush.CreatedOn), cast(cast(ush.CreatedOn as date) as datetime2)) as Date
    , count(*) as DeletedCount
    , '3. Mango'
from "BOR-KONGA-DB".Borneo.client.UserStatusHistory ush 
where ush.Status = 4
    and ush.CreatedBy = 0x3693
    and ush.CreatedOn >= '2019-07-29 09:00:00.000'
group by dateadd(hour, datepart(hour, ush.CreatedOn), cast(cast(ush.CreatedOn as date) as datetime2))
;

select
    format(Date, 'yyyy-MM-dd HH') as Date
    , DeletedCount
    , Project
from #Del
where date >= format(getdate(), 'yyyyMM01')
