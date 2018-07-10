select
    pc.Code
    ,crf.ClientId
    ,c.fio
    ,c.Email
--    ,prf.ProductId
--    ,p.StatusName as ProductStatus
from mkt.PromoCodes pc
inner join mkt.ClientReductionFactor crf on crf.ReductionFactorId = pc.Id
inner join Client.vw_client c on c.clientid = crf.ClientId
left join mkt.ProductReductionFactor prf on prf.ClientReductionFactorId = crf.Id
left join prd.vw_product p on p.Productid = prf.ProductId
where pc.code in ('QOMU','LCL6')
    and prf.ProductId is null