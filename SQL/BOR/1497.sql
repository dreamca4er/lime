drop procedure if exists dict.spGetPlaceHierarchy 
;
GO

create procedure dict.spGetPlaceHierarchy 
    @inputGuids nvarchar(max)
as
begin
declare 
    @aolevel int = 0
    ,@iter int = 0
;

drop table if exists #tmp
;

with unnest as 
(
    select
        cast(value as uniqueidentifier) as guid
    from openjson(@inputGuids)
)

select 
    un.guid as initialGuid
    ,un.guid as currentGuid
    ,ao.parentguid
    ,ao.name
    ,ao.aolevel
    ,ao.okato
    ,row_number() over (order by un.guid) as rn
into #tmp
from unnest un
cross apply
(
    select top 1
        ao.parentguid
        ,ao.formalname + ' ' + ao.shortname as name
        ,ao.aolevel
        ,ao.okato
    from dict.addrobj ao
    where ao.aoguid = un.guid
    order by case when ao.actstatus = 1 then 1 else 2 end
        ,ao.enddate desc

) ao
;

select @iter = (select count(*) from #tmp)
;

while @iter != 0
    begin

    select @aolevel = (select aolevel from #tmp where rn = @iter)
    ;

    while @aolevel != 1
        begin

        insert into #tmp
        select
            t.initialGuid
            ,t.parentguid
            ,ao.parentguid
            ,ao.name
            ,ao.aolevel
            ,ao.okato
            ,t.rn
        from #tmp t
        outer apply 
        (
            select top 1
                ao.parentguid
                ,ao.formalname + ' ' + ao.shortname as name
                ,ao.aolevel
                ,ao.okato
            from dict.addrobj ao   
            where ao.aoguid = t.parentguid
            order by case when ao.actstatus = 1 then 1 else 2 end
                ,ao.enddate desc
        ) ao
        where rn = @iter
            and t.aolevel = @aolevel
        ;

        select @aolevel = min(aolevel) 
        from #tmp
        where rn = @iter
        ;

    end

    select @iter = @iter - 1;
end
;

select
    initialGuid
    ,currentGuid
    ,name
    ,aolevel
    ,okato
from #tmp
order by initialGuid, aolevel desc
end
GO
;
--exec dict.spGetPlaceHierarchy '["0da8baca-6f3a-4fb7-8858-62afa72bbbf6"]'

drop procedure if exists dict.spGetBuildingInfo
;
GO
create procedure dict.spGetBuildingInfo
    @inputGuids nvarchar(max)
as
begin

with unnest as 
(
    select
        cast(value as uniqueidentifier) as guid
    from openjson(@inputGuids)
)

select
    houseguid
    ,housenum
    ,buildnum
    ,strucnum
    ,postalcode
from dict.houseactive
where houseguid in (select guid from unnest)
end
go

--exec dict.spGetBuildingInfo '["cf39a00f-cd4c-4202-9057-8a40e575b918"]'