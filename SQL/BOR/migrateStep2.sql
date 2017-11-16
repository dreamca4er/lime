select count(*)--top 1000000
--    pa.address
--    ,pa.cityid
--    ,pa.streetid
--    ,ual.House
--    ,ual.Block
--    ,ha.address
--    ,ha.HOUSEGUID

--    pa.*
--    ,ual.House
--    ,ual.Block
--    ,ha.address
--    ,ha.HOUSEGUID
from
(
    select *
    from mg.parsedAddresses pa
    where pa.product = 'lime'
        and pa.aoguid is not null
) pa
   
left join prod.UserAddressesLime ual on ual.CityId = pa.cityid
    and (isnull(ual.StreetId, 0) = isnull(pa.streetid, 0))
--outer apply
--(
--    select top 1
--        address
--        ,HOUSEGUID
--    from dict.houseactive ha
--    where ha.aoguid = pa.aoguid
--        and ha.address like concat(pa.address, N', д '
--                                    ,replace(replace(ual.House, N'корпус', ''), ' ', '%')
--                                    ,replace(N' к ' + ual.Block, ' ', '%')
--                                    )
--    order by len(ha.address) desc
--) ha
left join dict.houseactive ha on ha.aoguid = pa.aoguid
        and ha.address like concat(pa.address, N', д '
                                    ,replace(replace(ual.House, N'корпус', ''), ' ', '%')
                                    ,replace(N' к ' + ual.Block, ' ', '%')
                                    )

--1567168
