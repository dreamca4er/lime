--create table br8798
--(
--    id int identity(1, 1)
--    , FileStreamId uniqueidentifier not null primary key
--    , ClientId int
--    , MinioPath nvarchar(100)
--)
--;

--create table dbo.br8798_check
--(
--    id int identity(1, 1)
--    , FileStreamId uniqueidentifier not null primary key
--    , ClientId int
--    , Filesize int
--)
--create index ix_dbo_br8798_check_FileStreamId_Filesize on dbo.br8798_check(FileStreamId, Filesize)
insert br8798
select
    cdm.FileStreamId
    , ClientId
    , case
        when DocumentType < 100
        then 'Clients/' + cast(ClientId as nvarchar(20)) + '/Uploads/' + lower(cast(cdm.FileStreamId as nvarchar(36)))
        else 'Clients/' + cast(ClientId as nvarchar(20)) + '/' + cdm.ContractNumber+ '/' + lower(cast(cdm.FileStreamId as nvarchar(36)))
    end as MinioPath
from doc.ClientDocumentMetadata cdm
where (exists
    (
        select 1 from doc.ClientDocuments cd
        where cd.stream_id = cdm.FileStreamId
    )
    or
    exists
    (
        select 1 from BorneoFiles.doc.ClientDocuments cd
        where cd.stream_id = cdm.FileStreamId
    ))
    and CreatedOn >= '20180901'
    and CreatedOn <= '20181001'
    and not exists
    (
        select 1 from br8798 b2
        where b2.FileStreamId = cdm.FileStreamId
    )
/

select count(*) -- delete top (10000) cd -- select top 10 cdm.*
from doc.ClientDocuments cd
inner join dbo.br8798_check c on c.FileStreamId = cd.stream_id
    and c.Filesize > 0
left join doc.ClientDocumentMetadata cdm on cdm.FileStreamId = cd.stream_id
where c.ClientId in (1351028)

select count(*) -- delete top (10000) cd -- select top 10 cdm.*
from BorneoFiles.doc.ClientDocuments cd
inner join dbo.br8798_check c on c.FileStreamId = cd.stream_id
    and c.Filesize > 0
left join doc.ClientDocumentMetadata cdm on cdm.FileStreamId = cd.stream_id
where c.ClientId in (2346471)
/
set nocount on
;
drop table if exists #cd
;

select cd.stream_id, cd.cached_file_size, cast('Borneo' as nvarchar(20)) as DB
into #cd
from doc.ClientDocuments cd
;

insert #cd
select cd.stream_id, cd.cached_file_size, 'BorneoFiles'
from BorneoFiles.doc.ClientDocuments cd
;

create clustered index IX_cd_DB_stream_id on #cd(DB, stream_id)
;
select 
    count(*) as TotalFilesCount
    , sum(cd.cached_file_size / power(1024.0, 3)) as TotalFilesSize
    , count(iif(c.id > 0, 1, null)) as ToDeleteCount
    , sum(iif(c.id > 0, cd.cached_file_size / power(1024.0, 3), 0)) as ToDeleteSize
    , DB
from #cd cd
left join dbo.br8798_check c on c.FileStreamId = cd.stream_id
    and c.Filesize > 0
group by DB


/*
select 
    count(*) as OrphanedCount
    , sum(cd.cached_file_size / power(1024.0, 3)) as OrphanedSize
    , 'doc.ClientDocuments' as TableName
from doc.ClientDocuments cd
where not exists
    (
        select 1 from doc.ClientDocumentMetadata cdm 
        where cdm.FileStreamId = cd.stream_id
    )
union all
select 
    count(*) as OrphanedCount
    , sum(cd.cached_file_size / power(1024.0, 3)) as OrphanedSize
    , 'BorneoFiles.doc.ClientDocuments' as TableName
from BorneoFiles.doc.ClientDocuments cd
where not exists
    (
        select 1 from doc.ClientDocumentMetadata cdm 
        where cdm.FileStreamId = cd.stream_id
    )
*/
select count(*) as FilesToCheck
from br8798 b
where not exists
    (
        select 1 from br8798_check b2
        where b2.FileStreamId = b.FileStreamId
    )
;

set nocount off
;
/
select top 10
    b.ClientId
    , cdm.CreatedOn
    , cdm.FileName
    , cdm.FileStreamId
    , cdm.ContractNumber
    , cdm.DocumentType
    , iif(cd.stream_id is null, 'Yes', 'No') as "Borneo ClientDocuments Deleted"
    , iif(bfcd.stream_id is null, 'Yes', 'No') as "BorneoFiles ClientDocuments Deleted"
from br8798 b
inner join doc.ClientDocumentMetadata cdm on b.FileStreamId = cdm.FileStreamId
left join doc.ClientDocuments cd on cd.stream_id = cdm.FileStreamId
left join BorneoFiles.doc.ClientDocuments bfcd on bfcd.stream_id = cdm.FileStreamId
where bfcd.stream_id is not null
order by cdm.CreatedOn desc
-- 2201557
-- 1196872
/

select  
    dateadd(month, datediff(month, 0, cast(cdm.CreatedOn as date)), 0) as mnth
    , count(*)
    , sum(cd.cached_file_size) / power(1024.0, 3) as filessize
    , DB
from #cd cd
inner join doc.ClientDocumentMetadata cdm on cdm.FileStreamId = cd.stream_id
group by dateadd(month, datediff(month, 0, cast(cdm.CreatedOn as date)), 0), DB
;
