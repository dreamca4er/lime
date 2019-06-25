select top 100 
    mp.id
    , mp.ProductId
    , mp.Amount
    , pa.ErrorPaymentAmount
    , ec.EuroCost
    , pa.ErrorPaymentAmount * pa.ErrorPaymentAmount
    , mp.ConditionSnapshot
from br8687 br
left join mts.MintosProduct mp on mp.MintosId = br.MintosId
left join mts.MintosMessage mm on mm.ProductId = mp.id
    and mm.CreatedOn >= '20190509'
    and mm.CreatedOn < '20190510'
    and mm.Content like '%by a significant margin"]}'
outer apply
(
    select cast(substring(mm.Content, 35, 6) as numeric(10, 3)) as ErrorPaymentAmount
) pa
outer apply
(
    select round(1 / cast(json_value(mp.ConditionSnapshot, '$[0].ExchangeRate') as numeric(18, 6)), 2) as EuroCost
) ec
where mm.id is not null
    and mp.id = 68143
    
select *
from mts.MintosMessage
where ProductId = 68143