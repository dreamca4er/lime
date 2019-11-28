declare @query nvarchar(4000)= 
'
use $dbname
;

with cte as 
(
    select
        sch.name as SchemaName
        , t.name as TableName
        , sum(s.used_page_count) as used_pages_count
        , sum (case
                when i.index_id < 2 
                then in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count
                else lob_used_page_count + row_overflow_used_page_count
            end) as pages
        , sum(case when i.index_id < 2 then s.row_count end) as RowCounts
        , cc.ColumnCount
    from sys.dm_db_partition_stats s 
    inner join sys.tables t on s.object_id = t.object_id
    left join sys.schemas sch on t.schema_id = sch.schema_id
    inner join sys.indexes i on i.object_id = t.object_id
        and s.index_id = i.index_id
    outer apply
    (
        select count(distinct c.column_name) as ColumnCount
        from information_schema.columns c
        where t.name = c.table_name
    ) cc
    where not (t.Name = ''TableSize'' and sch.name = ''bi'')
    group by sch.name, t.name, cc.ColumnCount
)

select
    db_name() as DatabaseName
    , cte.SchemaName
    , cte.TableName
    , cast(cte.pages * 8.0 / 1024 as numeric(18, 3)) as TableSizeInMB
    , cast(iif(cte.used_pages_count > cte.pages
            , cte.used_pages_count - cte.pages, 0) * 8.0 / 1024 as decimal(10,3)) as IndexSizeInMB
    , cte.RowCounts
    , cte.ColumnCount
from cte
order by 2 desc
'
;
/*
drop table if exists bi.TableSize
;


create table bi.TableSize
(
    DatabaseName nvarchar(100)
    , SchemaName nvarchar(100)
    , TableName nvarchar(100)
    , TableSizeInMB numeric(18, 3)
    , IndexSizeInMB numeric(18, 3)
    , RowCounts bigint
    , ColumnCount int 
    , ChangeType nvarchar(100)
    , Date datetime2
)
;
select * from bi.tablesize
*/
declare @i int
;

drop table if exists #temp
;

select row_number() over (order by 1/0) as id, DBName
into #temp
from (values ('Borneo'), ('Warehouse'), ('BorneoLimeBus'), ('BorneoMangoBus'), ('BorneoKongaBus')) v(DBName)
where db_id(DBName) is not null
;

select @i = count(*)
from #temp
;

drop table if exists #TableInfo
;

create table #TableInfo
(
    DatabaseName nvarchar(100)
    , SchemaName nvarchar(100)
    , TableName nvarchar(100)
    , TableSizeInMB numeric(18, 3)
    , IndexSizeInMB numeric(18, 3)
    , RowCounts bigint
    , ColumnCount int
)
;

while @i != 0
begin
    declare @CurrentDBName nvarchar(100) = (select DBName from #temp where id = @i)
    ;
    
    declare @CurrentQuery nvarchar(max) = replace(@query, '$dbname', @CurrentDBName)
    ;
    
    insert into #TableInfo
    exec sp_executesql @CurrentQuery
    ;
    
    set @i = @i - 1
    ;
end
;
--truncate table bi.TableSize
--insert bi.TableSize
--select *, 'Init', getdate()
--from #TableInfo
--;

insert bi.TableSize
select
    ti.*
    , case
        when PrevInfo.ChangeType = 'Deleted' or PrevInfo.TableName is null
        then 'Created'
        when PrevInfo.ColumnCount != ti.ColumnCount
        then 'Col count changed'
        when PrevInfo.TotalSize < ti.TableSizeInMB + ti.IndexSizeInMB
        then 'Size increased'
        when PrevInfo.TotalSize > ti.TableSizeInMB + ti.IndexSizeInMB
        then 'Size decreased'
        when PrevInfo.RowCounts < ti.RowCounts
        then 'RowCount increased'
        when PrevInfo.RowCounts > ti.RowCounts
        then 'RowCount decreased'
    end as ChangeType
    , getdate()
from #TableInfo ti
outer apply
(
    select top 1 ts.*, ts.TableSizeInMB + ts.IndexSizeInMB as TotalSize
    from bi.TableSize ts
    where ts.DatabaseName = ti.DatabaseName
        and ts.SchemaName = ti.SchemaName
        and ts.TableName = ti.TableName
    order by ts.Date desc
) PrevInfo
where PrevInfo.TableName is null
    or PrevInfo.TotalSize != ti.TableSizeInMB + ti.IndexSizeInMB
    or PrevInfo.RowCounts != ti.RowCounts
    or PrevInfo.ColumnCount != ti.ColumnCount

union all

select
    ts.DatabaseName
    , ts.SchemaName
    , ts.TableName
    , 0 as TableSizeInMB
    , 0 as IndexSizeInMB
    , 0 as RowCounts
    , 0 as ColumnCount
    , 'Deleted' as ChangeType
    , getdate() as Date
from bi.TableSize ts
left join #TableInfo ti on ti.DatabaseName = ts.DatabaseName
    and ti.SchemaName = ts.SchemaName
    and ti.TableName = ts.TableName
where not exists
    (
        select 1 from bi.TableSize ts2
        where ts2.DatabaseName = ts.DatabaseName
            and ts2.SchemaName = ts.SchemaName
            and ts2.TableName = ts.TableName
            and ts2.Date > ts.Date
    )
    and (ts.ChangeType is null or ts.ChangeType != 'Deleted')
    and ti.TableName is null
