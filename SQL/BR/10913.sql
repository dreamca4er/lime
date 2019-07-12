select
    mp.ProductId
    , mp.ProductStatusName
    , mp.Amount
    , mp.ContractPayDay
    , mp.RealDatePaid
    , mp.PublishDate
    , mp.public_id
    , mp.MintosId
    , b.Status
from mts.vw_MintosProduct mp
left join br10913 b on b.MintosId = mp.MintosId
where mp.PublishDate >= '20190701'


select *
from br10913 b 
where CreatedOn >= '20190701'

create index IX_br10913_MintosId on br10913(MintosId)