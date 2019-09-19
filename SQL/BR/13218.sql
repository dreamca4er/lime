select
    mp.MintosProductId
    , md.id as MintosId
    , 'https://www.mintos.com/ru/' + mp.public_id as MintosUrl
    , sl.ProductId
    , p.ContractNumber
    , md.status as MintosStatus
    , mp.MintosProductStatusName
    , p.StartedOn
    , mp.PublishDate
    , datediff(d, sl.StartedOn, getdate()) + 1 as OverdueDays
--into dbo.br13218
from prd.vw_statusLog sl
inner join prd.Product p on p.id = sl.ProductId
inner join bi.MintosData md on md.lender_id = sl.ProductId
inner join mts.vw_MintosProduct mp on mp.ProductId = sl.ProductId
where sl.Status = 4
    and sl.StartedOn between dateadd(d, -59, cast(getdate() as date)) and dateadd(d, -49, cast(getdate() as date)) 
    and not exists
    (
        select 1 from prd.vw_statusLog sl2
        where sl2.ProductId = sl.ProductId
            and sl2.StartedOn > sl.StartedOn
    )
    and p.ProductType = 1
    and md.status = 'active'