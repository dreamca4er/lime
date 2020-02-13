select
    p.ClientId
    , p.Productid
    , p.ContractNumber
    , max(long.BuiltOn) as ProlongBuiltOn
    , count(*) as ProlongCnt
    , p.StatusName
from prd.vw_product p
inner join prd.vw_Prolongation long on long.ProductId = p.Productid
where long.BuiltOn >= '20200123'
group by 
    p.ClientId
    , p.Productid
    , p.ContractNumber
    , p.StatusName