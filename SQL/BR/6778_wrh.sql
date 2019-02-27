with r as 
(
    select 
        req.CreatedOn as RequestCreatedOn
        , req.Id as RequestId
        , lcp.LocalClientId
        , lcp.ProjectClientId
        , a.*
    from wrh.EquifaxAddress a
    inner join wrh.EquifaxResponse er on er.Id = a.EquifaxResponseId
    inner join wrh.EquifaxRequest req on req.id = er.EquifaxRequestId
    inner join wrh.LocalClientProject lcp on lcp.LocalClientId = req.LocalClientId
        and lcp.Project = 1
        and lcp.ProjectClientId in (select * from "BOR-LIME-DB".Borneo.dbo.br6778_2)
)

select *
into LimeZaim_Website.dbo.br6778_lime
from r
;
/
create index IX_dbo_br6778_lime on dbo.br6778_lime(ProjectClientId, Date, Type, RequestCreatedOn)
;
/
select distinct
    ProjectClientId
    , Date
    , Type
    , Address
into LimeZaim_Website.dbo.br6778_lime_ready
from LimeZaim_Website.dbo.br6778_lime r
where not exists 
    (
        select 1 from LimeZaim_Website.dbo.br6778_lime r2
        where r2.ProjectClientId = r.ProjectClientId
            and r2.Date = r.Date
            and r2.Type = r.Type
            and r2.RequestCreatedOn > r.RequestCreatedOn
    )
/

select *
from Col