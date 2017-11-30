drop table if exists [mg].[readyAddresses]
;

CREATE TABLE [mg].[readyAddresses]  ( 
	[CityId]     	int NULL,
	[StreetId]   	int NULL,
	[cityTitle]  	nvarchar(50) NULL,
	[streetTitle]	nvarchar(50) NULL,
	[House]      	nvarchar(50) NULL,
	[Block]      	nvarchar(50) NULL,
	[aoguid]     	nvarchar(36) NULL,
	[HOUSEGUID]  	nvarchar(255) NULL,
	[address]    	nvarchar(316) NULL,
	[regioncode] 	nvarchar(4) NULL,
	[postalcode] 	nvarchar(6) NULL,
    product         nvarchar(10) not null
	)
;

with lime as 
(
    select
        ual.CityId
        ,ual.StreetId
        ,ual.House
        ,ual.Block
        ,pa.cityTitle
        ,pa.streetTitle
        ,pa.aoguid
        ,coalesce(ha.address
                    ,concat(pa.cityTitle
                            , isnull(', ' + pa.streetTitle, '')
                            , isnull(N', д ' + ual.House, '')
                            , isnull(N', к ' + ual.Block, '')
                            )) as address
        ,ha.HOUSEGUID
        ,row_number() over (partition by ual.CityId, ual.StreetId, ual.House, ual.Block order by len(ha.address)) as rn
        ,pa.regioncode
        ,pa.postalcode
        ,pa.product
    from prod.UserAddresseslime ual
    inner join mg.parsedAddresses pa  on ual.CityId = pa.cityid
        and (isnull(ual.StreetId, 0) = isnull(pa.streetid, 0))
        and pa.product = 'lime'
    left join dict.houseactive ha on 1 = 1
            and ha.address like concat(pa.address, N', д '
                                        ,replace(replace(ual.House, N'корпус', ''), ' ', '%')
                                        ,isnull(N' к ' + ual.Block, '')
                                        )
            and ha.aoguid = pa.aoguid
    where ual.CityId is not null
        and pa.streetid != 0
        and pa.aoguid is not null
)


,konga as 
(
    select
        ual.CityId
        ,ual.StreetId
        ,ual.House
        ,ual.Block
        ,pa.cityTitle
        ,pa.streetTitle
        ,pa.aoguid
        ,coalesce(ha.address
                    ,concat(pa.cityTitle
                            , isnull(', ' + pa.streetTitle, '')
                            , isnull(N', д ' + ual.House, '')
                            , isnull(N', к ' + ual.Block, '')
                            )) as address
        ,ha.HOUSEGUID
        ,row_number() over (partition by ual.CityId, ual.StreetId, ual.House, ual.Block order by len(ha.address)) as rn
        ,pa.regioncode
        ,pa.postalcode
        ,pa.product
    from prod.UserAddresseskonga ual
    inner join mg.parsedAddresses pa  on ual.CityId = pa.cityid
        and (isnull(ual.StreetId, 0) = isnull(pa.streetid, 0))
        and pa.product = 'konga'
    left join dict.houseactive ha on 1 = 1
            and ha.address like concat(pa.address, N', д '
                                        ,replace(replace(ual.House, N'корпус', ''), ' ', '%')
                                        ,isnull(N' к ' + ual.Block, '')
                                        )
            and ha.aoguid = pa.aoguid
    where ual.CityId is not null
        and pa.streetid != 0
        and pa.aoguid is not null
)


,mango as 
(
    select
        ual.CityId
        ,ual.StreetId
        ,ual.House
        ,ual.Block
        ,pa.cityTitle
        ,pa.streetTitle
        ,pa.aoguid
        ,coalesce(ha.address
                    ,concat(pa.cityTitle
                            , isnull(', ' + pa.streetTitle, '')
                            , isnull(N', д ' + ual.House, '')
                            , isnull(N', к ' + ual.Block, '')
                            )) as address
        ,ha.HOUSEGUID
        ,row_number() over (partition by ual.CityId, ual.StreetId, ual.House, ual.Block order by len(ha.address)) as rn
        ,pa.regioncode
        ,pa.postalcode
        ,pa.product
    from prod.UserAddressesmango ual
    inner join mg.parsedAddresses pa  on ual.CityId = pa.cityid
        and (isnull(ual.StreetId, 0) = isnull(pa.streetid, 0))
        and pa.product = 'mango'
    left join dict.houseactive ha on 1 = 1
            and ha.address like concat(pa.address, N', д '
                                        ,replace(replace(ual.House, N'корпус', ''), ' ', '%')
                                        ,isnull(N' к ' + ual.Block, '')
                                        )
            and ha.aoguid = pa.aoguid
    where ual.CityId is not null
        and pa.streetid != 0
        and pa.aoguid is not null
)

insert into [mg].[readyAddresses]
select
    a.CityId
    ,a.StreetId
    ,a.cityTitle
    ,a.streetTitle
    ,a.House
    ,a.Block
    ,a.aoguid
    ,a.HOUSEGUID
    ,a.address
    ,a.regioncode
    ,a.postalcode
    ,a.product
from lime a
where rn = 1

union

select
    a.CityId
    ,a.StreetId
    ,a.cityTitle
    ,a.streetTitle
    ,a.House
    ,a.Block
    ,a.aoguid
    ,a.HOUSEGUID
    ,a.address
    ,a.regioncode
    ,a.postalcode
    ,a.product
from konga a
where rn = 1

union

select
    a.CityId
    ,a.StreetId
    ,a.cityTitle
    ,a.streetTitle
    ,a.House
    ,a.Block
    ,a.aoguid
    ,a.HOUSEGUID
    ,a.address
    ,a.regioncode
    ,a.postalcode
    ,a.product
from mango a
where rn = 1

/

