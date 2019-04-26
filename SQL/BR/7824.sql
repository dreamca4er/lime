set transaction isolation level read uncommitted
;

select count(*)
from 
(
select distinct
    CityName + N',' + StreetName + N',д ' + House + isnull(N',к ' + nullif(Block, ''), '') as Address
from dbo.UserAddresses
where StreetName is not null
    and House is not null
) a