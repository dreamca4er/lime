
CREATE PROCEDURE [dict].[spGetAddress]
@str nvarchar(200)
,@aoguid nvarchar(200) = null --uniqueidentifier = null
as
begin

declare
    @ptrn nvarchar(400)
    ,@cnt integer
    ,@limit integer = 8
    ,@dist integer = 4
    ,@neededguid uniqueidentifier = cast(nullif(@aoguid, '') as uniqueidentifier)
    ,@lastAddressPart nvarchar(10) = case
                                        when charindex(' ', reverse(@str)) > 0
                                        then reverse(substring(reverse(@str), 1,  charindex(' ', reverse(@str)) - 1))
                                        else ''
                                      end
    ,@addressWOLastPart nvarchar(200) = case 
                                            when charindex(' ', reverse(@str)) > 0
                                            then rtrim(ltrim(substring(@str, 0, len(@str) - charindex(' ', reverse(@str)) + 1)))
                                            else ''
                                        end

declare
    @preLastAddressPart nvarchar(10) = case
                                            when charindex(' ', reverse(@addressWOLastPart)) > 0
                                            then reverse(substring(reverse(@addressWOLastPart), 1,  charindex(' ', reverse(@addressWOLastPart)) - 1))
                                            else ''
                                        end
    ,@tmpvar nvarchar(200)
    ,@region int = null

;
    create table #forStr
    (
        id int identity(1, 1)
        ,stringPart nvarchar(100)
        ,realId int
    )
;
    select @region = (select regioncode from dict.hierarchy h2 where h2.aoguid = @aoguid)
    select @str = replace(rtrim(ltrim(@str)), ',', ' ')
;

    insert into #forStr (stringPart)
    select *
    from string_split(@str, ' ')
    where value != ''
;

    delete from #forstr
    where stringPart in 
                        (
                            select SCNAME
                            from dict.socrbase
                            where SCNAME is not null
                        )
;
    update f 
    set f.realId = f2.rn
    from #forStr f
    inner join
    (
        select ft.id, row_number() over (order by ft.id) as rn
        from #forStr ft
    ) f2 on f2.id = f.id
;
    with cte (stringPart, realId) as
	(
		select cast('"' + l.stringPart + '*"' as nvarchar(512))
			, l.realId
		from #forStr l
		where l.realId = 1
		union all 
		select cast( c.stringPart + ',"' + ln.stringPart + '*"' as nvarchar(512))
			, ln.realId
		from #forStr ln
		inner join cte c on c.realId + 1 = ln.realId
	)

	select top 1 
        @ptrn = 
        case 
            when realId = 1 then stringPart
            else 'NEAR((' + stringPart + '), ' + cast(@dist as nvarchar(2)) + ', true)'
        end 
	from cte
	order by realId desc
;
    
--print @ptrn
print 'addr start: ' + format(getdate(), 'HH:mm:ss')
print @ptrn
;
    select top (@limit)
        cast(null as nvarchar(50)) as houseguid
        ,aoguid
        ,postalcode
        ,name as address
        ,regioncode
        ,centstatus
        ,aolevel
    into #addr
    from dict.hierarchy
    where 1 = 1
        and contains(name, @ptrn)
        and (parentguid = @neededguid or @neededguid is null)
    order by
        case 
            when aolevel = 1 then 1
            when aolevel = 4 then 2 
            else 3 
        end
        ,case 
            when centstatus not in (0, 4) then 1
            when centstatus = 4 then 2
            when centstatus = 0 then 3
        end
        ,centstatus desc
        ,address

    ;
    select @cnt = (select count(*) from #addr)
    ;


print 'house start: ' + format(getdate(), 'HH:mm:ss')

    ;with h as 
    (
        select top (@limit - @cnt) *
        from dict.houseactive p
        where 1 = 1 
            and (regioncode = @region or @region is null)
            and contains(address, @ptrn)
            and @cnt < @limit
            --and aoguid = 'BC9D3069-9234-409F-A11E-2549F8AA0482'
            and (aoguid = @neededguid or @neededguid is null)
        order by
            case 
                when centstatus not in (0, 4) then 1
                when centstatus = 4 then 2
                when centstatus = 0 then 3
            end
            ,centstatus desc
            ,address
    )

    ,un as
    (
        select
            houseguid
            ,aoguid
            ,postalcode
            ,address
            ,regioncode
            ,centstatus
            ,aolevel
            ,0 as isHouse
        from #addr

        union

        select
            houseguid
            ,aoguid
            ,postalcode
            ,address AS houseaddr
            ,regioncode
            ,centstatus
            , 100
            ,1
        from h

    union

    select top (charindex(' ', reverse(@str)))
        null
        ,h.aoguid
        ,h.postalcode
        ,case 
            when @preLastAddressPart like '[0-9]%'
            then h.name + N', ä ' + @preLastAddressPart + N', ê ' + @lastAddressPart
            else h.name + N', ä ' + @lastAddressPart
        end
        ,h.regioncode
        ,1
        ,1
        ,1
    from dict.hierarchy h--(select @str as addr) a
    where h.aoguid = @aoguid
        and not exists
                    (
                        select 1 from #addr
                    )
        and not exists
                    (
                        select 1 from h
                    )
        and (@preLastAddressPart like '[0-9]%'
                or @lastAddressPart like '[0-9]%')
        
        and exists
                    (
                        select 1 from dict.houseactive ha
                        where ha.aoguid = @aoguid
                    )
        and @lastAddressPart != ''
    )
    select 
        cast(houseguid as uniqueidentifier) as houseguid
        ,cast(aoguid as uniqueidentifier) as aoguid
        ,postalcode
        ,address
        ,regioncode
        ,cast(isHouse as bit) as isHouse
    from un
    order by 
        aolevel --, centstatus
        ,case 
            when centstatus = 2 then 1
            when centstatus = 3 then 2
            when centstatus = 4 then 2
            else 3
        end
        ,address

print 'end: ' + format(getdate(), 'HH:mm:ss')
end
GO
