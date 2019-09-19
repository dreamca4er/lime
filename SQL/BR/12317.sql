insert dbo.br12317
select
    cast(id as int) as ClientId
    , N'Манго_0.11-0.20' as Type
--into dbo.br12317
from client.Client
where id in 
(

)
/
drop table if exists #op
;

select *
into #op
from col.tf_op('19000101', '20190723')
;

create index IX_op_ProductId_AssignDate_LastDayWasAssigned on #op(ProductId, AssignDate, LastDayWasAssigned)
;

drop table if exists #a
;

select *
into #a
from sts.vw_admins a
;

select
    b.Type
    , b.ClientId
    , op.ProductId
    , ii.CreatedOn as InteractionDate
    , cg.GroupName as ProductGroupName
    , #op.AssignDate as GroupAssignDate
    , isnull(cgh.CollectorName, a.Name) as InteractionCreatorName
    , isnull(cgh.CollectorGroupName, a.Roles) as InteractionCreatorGroup
    , bs.Description as InteractionStatusName
from dbo.br12317 b
inner join prd.Product p on p.ClientId = b.ClientId
inner join collector.OverdueProduct op on op.ProductId = p.id
inner join collector.InternalInteraction ii on ii.OverdueProductId = op.Id
left join bi.CollectorGroupHistory cgh on cgh.CollectorId = ii.CreatedBy
    and cgh.Date = cast(ii.CreatedOn as date)
left join #op on #op.ProductId = p.Id
    and cast(ii.CreatedOn as date) between #op.AssignDate and #op.LastDayWasAssigned
left join col.vw_cg cg on cg.GroupId = #op.CollectorGroupId
left join ecc.EnumInteractionBusinessStatus bs on bs.Id = ii.Status
left join #a a on a.id = ii.CreatedBy