drop table if exists dict.houseactive
;

with m as 
(
select
    HOUSEGUID
    ,max(ENDDATE) as ENDDATE
from dict.house
group by HOUSEGUID
)

select
    row_number() over (order by houseguid) as id
    ,h.HOUSEGUID
    ,h.AOGUID
    ,h.POSTALCODE
    ,hi.name
    + concat(
        case 
            when h.ESTSTATUS = 1 then N'влд '
            when h.ESTSTATUS in (2, 3, 5) then N'д '
            else ''
        end + h.HOUSENUM
        ,isnull(' к ' + h.BUILDNUM, '')
        ,isnull(case
                    when h.STRSTATUS = 1
                    then N' стр '
                    else N' сооружение '
                end + h.STRUCNUM, '')
        ) as HOUSENUM
    ,hi.regioncode
    ,hi.centstatus
into dict.houseactive
from dict.house h
inner join dict.hierarchy hi on h.AOGUID = hi.AOGUID
inner join m on m.houseguid = h.HOUSEGUID
    and m.enddate = h.ENDDATE
    and h.enddate > getdate()
    and h.STARTDATE < getdate()
;

alter table dict.houseactive
alter column id int not null
;

alter table dict.houseactive add constraint PK_houseactive_id primary key (id)
;

create fulltext index  on dict.houseactive (houseaddr) key index PK_houseactive_id
with (change_tracking auto)
;

