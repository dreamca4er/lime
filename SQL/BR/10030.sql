select
    mp.MintosProductId
    , b.MintosId
    , snap.Status as MintosStatus
    , mp.MintosProductStatus
    , mp.MintosProductStatusName
    , m.status
--update m set Status = 4
from dbo.br10030 b
outer apply openjson(b.Data)
with
(
    lender_id int '$.lender_id'
    , status nvarchar(20) '$.status'
) snap
left join mts.vw_MintosProduct mp on mp.MintosId = b.MintosId
    and mp.ProductId = snap.lender_id
left join mts.MintosProduct m on m.id = mp.MintosProductId
where snap.Status = 'finished'
    and mp.MintosProductStatus != 4