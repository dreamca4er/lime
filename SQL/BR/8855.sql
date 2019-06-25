declare
    @SearchString nvarchar(20) = N'207'
    , @Padding int = 100
;

declare
    @SearchStringlen int = len(@SearchString)
    , @PatString nvarchar(20) = '%' + @SearchString + '%'
;

with cte(Id, Template, PIndex, lvl, RealPIndex) as 
(
    select 
        Id
        , Template
        , patindex(@PatString, Template) as PIndex
        , 1 as lvl
        , patindex(@PatString, Template) as RealPIndex
    from rpt.TemplateRule
    where patindex(@PatString, Template) > 0
    
    union all
    
    select
        id
        , nt.NewTemplate as Template
        , patindex(@PatString, nt.NewTemplate) as PIndex
        , lvl + 1 as lvl
        , patindex(@PatString, nt.NewTemplate) + RealPIndex + @SearchStringlen - 1 as RealPIndex
    from cte
    outer apply
    (
        select substring(Template, cte.PIndex + @SearchStringlen, len(Template) - cte.PIndex) as NewTemplate
    ) nt
    where patindex(@PatString, nt.NewTemplate) > 0
)

,a as 
(
    select
        t.id
        , rtrim(ltrim(substring(t.Template, iif(RealPIndex <= @Padding, RealPIndex, RealPIndex - @Padding), @SearchStringlen + @Padding * 2))) as Pattern
    from cte
    inner join rpt.TemplateRule t on t.id = cte.id 
)

select *
from a
/
/*

select *
-- update tr set Template = replace(Template, 'support@lime-zaim.ru', 'support@konga.ru')
from rpt.TemplateRule tr
where id in (8)

   <Value>: 8 (383) 207-98-89</Va
   <Value>: 8 (383) 207-98-89</Va
   
   */

select FileStreamId, TemplateVersion
-- update cdm set TemplateVersion = null
from doc.ClientDocumentMetadata cdm
where ContractNumber = '7500073296'
select *
from 
/

select Timestamp
from rpt.TemplateRule
where Timestamp >= 0x000000000f6d2096

select *
from bi.RowVersionSnapshot
where Date >= '20190515'

/
select 
    e.*
    , tr.Template
    , rt.Name as ReportType
    , concat(proj, '_', e.id, '_', rt.Name, '.rdl')
from
(
    values
    (49, N'Указан офис 1402 для Лайма', N'Лайм')
    , (16, N'Указан офис 1402 для Лайма', N'Лайм')
    , (51, N'Указан офис 1402 для СКГ', N'Лайм')
    , (50, N'Указан офис 1402 для СКГ', N'Лайм')
    , (15, N'Указан офис 1402 для СКГ', N'Лайм')
    , (14, N'Указан офис 1402 для СКГ', N'Лайм')
    , (24, N'Указан офис 1501 для Лайма', N'Лайм')
    , (29, N'Указан офис 1501 для Лайма', N'Лайм')
    , (43, N'Указан офис 1501 для Лайма', N'Лайм')
    , (8, N'Указан Лайм и Манго, на других проектах такого нет', N'Манго')
    , (24, N'Указан адрес Лайма 1401', N'Конга')
    , (25, N'Указан адрес Лайма 1401', N'Конга')
    , (10, N'Указан адрес Лайма 1401', N'Конга')
) e(id, err, proj)
left join rpt.TemplateRule tr on tr.id = e.id
left join rpt.ReportType rt on rt.id = tr.ReportTypeId
where proj = N'Конга'
order by e.id
/

declare
    @Timestamp timestamp =
    (
        select min(timestamp)
        from bi.RowVersionSnapshot
        where Date >= '20190515'
    )
;

select cdm.FileStreamId, cdm.TemplateVersion
--update cdm set cdm.TemplateVersion = null
from doc.ClientDocumentMetadata cdm
inner join rpt.TemplateRule tr on tr.Id = cdm.TemplateVersion
    and tr.timestamp >= @Timestamp
where 1=1
    and cdm.RptId is null
    and cdm.IsMigrations = 0
    and cdm.IsDeleted = 0