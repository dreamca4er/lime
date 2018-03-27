
CREATE PROCEDURE [dict].[spGetPlaceHierarchy] 
    @inputGuids nvarchar(max)
as
begin
    declare 
        @lvl int = 0
        ,@iter int = 0
        ,@aolevel int = 0
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
        ,1 as lvl
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

        select @lvl = (select lvl from #tmp where rn = @iter)
        ;
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
                ,lvl + 1
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
                and t.lvl = @lvl
            ;

            select @lvl = max(lvl) 
            from #tmp
            where rn = @iter
            ;
            
            select @aolevel = aolevel
            from #tmp
            where lvl = @lvl
                and rn = @iter
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
    ;
/*
    select 
        cast('0DA8BACA-6F3A-4FB7-8858-62AFA72BBBF6' as uniqueidentifier) as initialGuid
        ,cast('0DA8BACA-6F3A-4FB7-8858-62AFA72BBBF6' as uniqueidentifier)  as currentGuid
        ,cast(N'Пермитина ул' as nvarchar(350)) as name
        ,cast(7 as int) as aolevel
        ,cast('50401377000' as nvarchar(11)) as okato
    from unnest

    union
 
    select 
        cast('0DA8BACA-6F3A-4FB7-8858-62AFA72BBBF6' as uniqueidentifier) as initialGuid
        ,cast('8DEA00E3-9AAB-4D8E-887C-EF2AAA546456' as uniqueidentifier)  as currentGuid
        ,cast(N'Новосибирск г' as nvarchar(350)) as name
        ,cast(4 as int) as aolevel
        ,cast('50401000000' as nvarchar(11)) as okato
    from unnest

    union

    select 
        cast('0DA8BACA-6F3A-4FB7-8858-62AFA72BBBF6' as uniqueidentifier) as initialGuid
        ,cast('1AC46B49-3209-4814-B7BF-A509EA1AECD9' as uniqueidentifier)  as currentGuid
        ,cast(N'Новосибирская обл' as nvarchar(350)) as name
        ,cast(1 as int) as aolevel
        ,cast('50000000000' as nvarchar(11)) as okato
    from unnest
*/
end
GO
