1735642    Тарасенко Роман - изменился адрес по прописке. Изменить вручную. Г. Брянск , улица Профсоюзов. Дом 9, кв.46

exec fias.dict.spgetaddress N'Г. Брянск , улица Профсоюзов. Дом 9'

SELECT 
    '58CCA0C5-888A-4464-A92B-3F310D813F67' AS houseguid
    ,'C471801D-FD88-47D4-A5E8-4E8B9F2F80A3' AS aoguid
    ,'241022' AS postalcode
    ,'Брянская обл,Брянск г,Профсоюзов ул,д 46' AS address
    ,32 AS regioncode
    ,1 AS isHouse
    
exec fias.dict.spGetPlacement 'C471801D-FD88-47D4-A5E8-4E8B9F2F80A3'

'414B71CF-921E-4BFC-B6E0-F7395D16AAEF'	'Брянская обл, Брянск г'
/
select *
from client.address
where clientid = 1735642
    and AddressType = 1
