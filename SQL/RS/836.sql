drop table if exists #cdm
;

select
    cdm.Id as ClientDocumentMetadataId
    , p.id as ProductId
    , p.CreatedOn as ProductCreatedOn
    , p.StartedOn as ProductStartedOn
    , cdm.CreatedOn as DocumentCreatedOn
    , cast(json_value(cdm.Command, '$.CreatedOn') as datetime2) as DocumentCommandCreatedOn
into #cdm
from doc.ClientDocumentMetadata cdm
inner join prd.Product p on p.ContractNumber = cdm.ContractNumber
where cdm.DocumentType = 101
    and p.CreatedOn < '20180601'
    and cdm.Command is not null
--    and cdm.ContractNumber = '1900019257'
    and cdm.IsDeleted = 0
    and cast(p.CreatedOn as date) != cast(cdm.CreatedOn as date)

/
select r.*, cdm.CreatedOn
from dbo.rs836 r
inner join doc.ClientDocumentMetadata cdm on cdm.id = r.ClientDocumentMetadataId
where r.DocumentCommandCreatedOn != cdm.CreatedOn
    and r.DocumentCommandCreatedOn = r.DocumentCreatedOn
select top 2
    ProductId
    , cdm.ClientId
    , cdm.ContractNumber
    , cast(json_value(cdm.Command, '$.CreatedOn') as datetime2) as DocumentCommandCreatedOn
    , cdm.CreatedOn
    , ProductCreatedOn
--update cdm set cdm.CreatedOn = ProductCreatedOn, cdm.Command = json_modify(cdm.Command, '$.CreatedOn', convert(nvarchar(100), c.ProductCreatedOn, 126))
from #cdm c
inner join doc.ClientDocumentMetadata cdm on c.ClientDocumentMetadataId = cdm.Id


select count(*)
from #cdm c
inner join doc.ClientDocumentMetadata cdm on c.ClientDocumentMetadataId = cdm.Id

select 
    p.ClientId
    , p.ContractNumber
    , p.CreatedOn
from #cdm c
inner join prd.product p on p.id = c.ProductId
/
with p as 
(
    select 
        id as ProductId
        , ClientId
        , ContractNumber
    from prd.product
    where ContractNumber in
    (
    '1900012574'
    , '1900013847'
    , '1900014339'
    , '1900014905'
    , '1900014682'
    , '1900013763'
    , '0965424004'
    , '1112154001'
    , '0602717001'
    , '1900014423'
    , '0619123001'
    , '1900013680'
    , '1900012902'
    , '1048033003'
    , '1900014020'
    , '1900012173'
    , '1900013575'
    , '1900014624'
    , '1900012529'
    , '1900012631'
    , '1900015860'
    , '1900013425'
    , '1797770001'
    , '1900015365'
    , '1900013374'
    , '1587177001'
    , '1833157001'
    , '1900014071'
    , '1900013993'
    , '1900015317'
    , '1627356001'
    , '1900011903'
    , '1900013237'
    , '1900012120'
    , '1900012788'
    , '1900015267'
    , '1195206003'
    , '1651298001'
    , '1900026736'
    , '1900029017'
    , '1900029619'
    , '1900028926'
    , '1900028979'
    , '1900029643'
    , '1900028294'
    , '1900026664'
    , '1900027946'
    , '1900028018'
    , '1900029879'
    , '1900033770'
    , '1900033851'
    , '1900033802'
    , '1900033902'
    , '1900033780'
    , '1900033538'
    , '1900034476'
    , '1900033841'
    , '1900033800'
    , '1900033756'
    , '1900033806'
    , '1900033690'
    , '1900033825'
    , '1900033891'
    , '1900033808'
    , '1900032169'
    , '1900033653'
    , '1900033852'
    , '1900033750'
    , '1900033814'
    , '1900033844'
    , '1900032304'
    , '1900033746'
    , '1900033817'
    , '1900033882'
    , '1900033775'
    , '1900033896'
    , '1900033761'
    , '1900033827'
    , '1900033900'
    , '1900033752'
    , '1900033895'
    , '1900026508'
    , '1900024918'
    , '1900025264'
    , '1900021601'
    , '1900024852'
    , '1900022869'
    , '1900025780'
    , '1900025757'
    , '1900023021'
    , '1900024437'
    , '1900016993'
    , '1900018981'
    , '1900017435'
    , '1900019019'
    , '1900021157'
    , '1900017272'
    , '1900021345'
    , '1900017227'
    , '1900018290'
    , '1900019838'
    , '1900018791'
    , '1900020007'
    , '1900020305'
    , '1900020412'
    , '1900018906'
    , '1900019334'
    , '1900017668'
    , '1900020768'
    , '1900020461'
    , '1900016902'
    , '1900016018'
    , '1900017249'
    , '1900019257'
    , '1900020705'
    , '1900020978'
    , '1900020026'
    , '1900018051'
    , '1900018301'
    , '1900019612'
    , '1900020276'
    , '1900017122'
    , '1900016506'
    , '1900016335'
    , '1900020938'
    , '1900021406'
    , '1900018113'
    , '1900021042'
    , '1900016348'
    , '1900019768'
    , '1900020985'
    , '1900017469'
    , '1900018974'
    , '1900016956'
    , '1900018685'
    , '1900034780'
    , '1900034514'
    , '1900035498'
    , '1900034614'
    )
)

select *
from p

left join #cdm cdm on cdm.ProductId = p.ProductId

where cdm.ProductId is null


/
select
    r.ClientDocumentMetadataId
    , cdm.ContractNumber
from dbo.rs836 r
inner join doc.ClientDocumentMetadata cdm on cdm.id = r.ClientDocumentMetadataId