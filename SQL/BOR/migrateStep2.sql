select 
    pa.address
    ,pa.cityid
    ,pa.streetid
    ,ual.House
    ,ual.Block
   ,ha.address
    ,ha.HOUSEGUID

--    pa.*
--    ,ual.House
--    ,ual.Block
--    ,ha.address
--    ,ha.HOUSEGUID
from mg.parsedAddresses pa  
left join prod.UserAddressesLime ual on ual.CityId = pa.cityid
    and (isnull(ual.StreetId, 0) = isnull(pa.streetid, 0))
left join dict.houseactive ha on ha.aoguid = pa.aoguid
        and ha.address like concat(pa.address, N', д '
                                    ,replace(replace(ual.House, N'корпус', ''), ' ', '%')
                                    ,replace(N' к ' + ual.Block, ' ', '%')
                                    )
where pa.product = 'lime'
    and pa.aoguid is not null
    and pa.cityid = 142388
    and pa.streetid = 891863
--group by
--    pa.address
--    ,pa.cityid
--    ,pa.streetid
--    ,ual.House
--    ,ual.Block
--having count(*) > 1
/

Северная Осетия - Алания Респ, Владикавказ г, Средняя ул	3037	288127	5	NULL


    

select *
from dict.house
where houseguid in ('e9767bb0-b9f6-4e7d-9efe-92936d4d565b', 'aba00da9-fc0b-437e-836f-1c08d09d4125')


