drop table if exists #m
;

select
    ProductId
    , PublishDate
    , MintosProductStatusName
    , ContractPayDay
into #m
from mts.vw_MintosProduct
where PublishDate >= '20190601'
;

select
    p.Productid
    , p.ClientId
    , p.ContractNumber
    , concat(c.LastName, ' ', c.FirstName, ' ', c.FatherName) as fio
    , p.StartedOn
    , p.Amount
    , m.ContractPayDay
    , p.StatusName
    , m.PublishDate
    , m.MintosProductStatusName
from #m m
left join prd.vw_product p on p.Productid = m.ProductId
left join client.client c on c.id = p.ClientId