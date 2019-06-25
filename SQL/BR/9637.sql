select
    mp.ProductId
    , p.ContractNumber
    , p.ClientId
    , mp.public_id
    , mp.MintosId
    , mp.ProductStatusName
    , mp.ProductStartedOn
    , mp.RealDatePaid
    , mp.MintosProductStatusName
    , json_value(d.Info, '$.status') as StatusFromMintosApi
from mts.vw_MintosProduct mp
inner join dbo.br9637 d on d.MintosId = mp.MintosId
inner join prd.product p on p.id = mp.ProductId