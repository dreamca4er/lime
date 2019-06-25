declare
    @id int = 78
;

/*
select tr.id, ReportTypeId, tr.StartedOn, p.PrevId, bi.rvdate(Timestamp) as TimestampDate, BuilderSnapshot
from rpt.TemplateRule tr
outer apply
(
    select top 1 tr2.id as PrevId
    from rpt.TemplateRule tr2
    where tr2.ReportTypeId = tr.ReportTypeId
        and tr2.StartedOn = tr.StartedOn
        and tr2.id < tr.id
    order by tr2.Version desc, tr2.Revision desc         
) p
where tr.id > @id
    and tr.ReportTypeId in  (100, 102)
order by tr.id desc
/
*/
/*

select *
from rpt.templaterule
where id in (82,81)
DROP TABLE [dbo].[br8976]

CREATE TABLE [dbo].[br8976]  ( 
	[project] 	nvarchar(100) NULL,
	[mnth]    	nvarchar(100) NULL,
	[name]    	nvarchar(100) NULL,
	[template]	nvarchar(max) NULL 
	)
GO
*/
with curr as 
(
    select
        id
        , StartedOn
        , BuilderSnapshot
        , ReportTypeId
        , Version
        , Revision
        , bi.rvdate(Timestamp) as TimestampDate
    from rpt.TemplateRule tr
    where tr.ReportTypeId in (100, 102)
        and not exists
        (
            select 1 from rpt.TemplateRule tr2
            where tr2.ReportTypeId = tr.ReportTypeId
                and tr2.StartedOn = tr.StartedOn
                and tr2.Version > tr.Version
        )
        and not exists
        (
            select 1 from rpt.TemplateRule tr2
            where tr2.ReportTypeId = tr.ReportTypeId
                and tr2.StartedOn = tr.StartedOn
                and tr2.Version >= tr.Version
                and tr2.Revision > tr.Revision
        )
)

--select *
--from curr
--order by 2
--/
--insert rpt.TemplateRule
--(
--    StartedOn,BuilderSnapshot,ReportTypeId,Version,Revision,template
--)
select top 2
    curr.StartedOn
    , curr.BuilderSnapshot
    , curr.ReportTypeId
    , curr.Version
    , curr.Revision + 1 as Revision
    , b.template
from dbo.br8976 b
outer apply
(
    select 
        iif(name = 'AgreementStTemplate.rdlc', 100, 102) as ReportTypeId
        , cast(right(b.mnth, 4) 
                + substring(b.mnth, 3, 2) 
                + left(replace(b.mnth, '03052019', '01052019'), 2) as date) as StartedOn
) r
inner join curr on curr.ReportTypeId = r.ReportTypeId
    and curr.StartedOn = r.StartedOn
    and curr.id <= @id
order by curr.StartedOn
/

select top 100 id, FileName, ClientId, ContractNumber, TemplateVersion
from doc.ClientDocumentMetadata
where 1=1
    and CreatedOn >= '2019-05-01 00:00:00.000'
    and ContractNumber >= '19'
    and DocumentType = 105
    and IsVisible = 1
    and ContractNumber = '1900528974'

/    
 id     ReportTypeId     StartedOn                PrevId     TimestampDate           
 -----  ---------------  -----------------------  ---------  ----------------------- 
 82     102              2018-01-01 00:00:00.000  45         2019-05-21 05:00:00.000 
 81     100              2018-01-01 00:00:00.000  44         2019-05-21 05:00:00.000
 