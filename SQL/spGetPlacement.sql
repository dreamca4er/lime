
CREATE PROCEDURE [dict].[spGetPlacement]
@aoguid nvarchar(200)
as
begin
    select
        h.placementGuid as aoguid
        ,hp.name
    from dict.hierarchy h
    inner join dict.hierarchy hp on hp.aoguid = h.placementGuid
    where h.aoguid = @aoguid
end
GO
