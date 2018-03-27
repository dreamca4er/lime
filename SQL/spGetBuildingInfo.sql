
CREATE PROCEDURE [dict].[spGetBuildingInfo]
    @inputGuids nvarchar(max)
as
begin

    with unnest as 
    (
        select
            cast(value as uniqueidentifier) as guid
        from openjson(@inputGuids)
    )
/*
    select distinct
        cast('CF39A00F-CD4C-4202-9057-8A40E575B918' as uniqueidentifier) as houseguid
        ,cast('16' as nvarchar(20)) as housenum
        ,cast(null as nvarchar(10)) as buildnum
        ,cast(null as nvarchar(10)) as strucnum
        ,cast('630078' as nvarchar(7)) as postalcode
    from unnest
*/
    select
        houseguid
        ,housenum
        ,buildnum
        ,strucnum
        ,postalcode
    from dict.houseactive
    where houseguid in (select guid from unnest)


end
GO
