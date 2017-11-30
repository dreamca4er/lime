
CREATE PROCEDURE [dict].[spGetAddress]
@str nvarchar(200)
,@aoguid nvarchar(200) = null --uniqueidentifier = null
as
begin

declare
    @ptrn nvarchar(400)
    ,@cnt integer
    ,@limit integer = 15
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
;

    with literals as 
	(
		select 
            concat('"', s.value, '*"') as literal
			, row_number() OVER (ORDER BY case when s.value like N'[0-9]%' then 2 else 1 end, value) rid
		from string_split(@str, ' ') s
        where s.value != ''
            and replace(s.value, ',', '') not in 
                            (
                                select SCNAME
                                from dict.socrbase
                                where SCNAME is not null
                            )
            and s.value != '-'
	)

	, cte (literal, rid) as
	(
		select cast(l.literal as nvarchar(512))
			, l.rid
		from literals l
		where l.rid = 1
		union all 
		select cast( c.literal + ' and ' + ln.Literal as nvarchar(512))
			, ln.rid
		from literals ln
		inner join cte c on c.rid + 1 = ln.rid
	)

	select top 1 @ptrn = literal
	from cte
	order by rid desc
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
            and contains(address, @ptrn)
            and @cnt < @limit
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
--        ,centstatus
--        ,aolevel
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
