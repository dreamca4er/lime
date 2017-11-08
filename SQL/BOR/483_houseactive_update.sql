drop table if exists dict.houseactive
;

select
    h.houseguid
    ,h.aoguid
    ,h.postalcode
    ,hi.name
    + ', '
    + concat(
        case 
            when h.ESTSTATUS = 1 then N'влд '
            when h.ESTSTATUS in (2, 3, 5) then N'д '
            else ''
        end + h.HOUSENUM
        ,isnull(N' к ' + h.BUILDNUM, '')
        ,isnull(case
                    when h.STRSTATUS = 1
                    then N' стр '
                    else N' сооружение '
                end + h.STRUCNUM, '')
        ) as address
    ,cast(hi.regioncode as int) as regioncode
    ,cast(hi.centstatus as smallint) as centstatus
into #houseactive
from dict.house h
inner join dict.hierarchy hi on h.AOGUID = hi.AOGUID
inner join m on m.houseguid = h.HOUSEGUID
    and m.enddate = h.ENDDATE
    and h.enddate > getdate()
    and h.STARTDATE < getdate()
where h.HOUSEGUID in
                    (
                        select houseguid
                        from dict.house_delta
                    )
    or h.aoguid in
                    (
                        select aoguid
                        from dict.hierarchyUpdate
                    )
;

delete from dict.houseactive
where houseguid in
                    (
                        select houseguid
                        from #houseactive
                    )
;

insert into dict.houseactive (HOUSEGUID,AOGUID,POSTALCODE,address,regioncode,centstatus)
select *
from #houseactive
;