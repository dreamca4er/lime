select 
    ap.ClientId
    , concat(c.LastName, ' ', c.FirstName, ' ', c.FatherName) as fio
    , ap.ProductId
    , ap.ContractNumber
    , ap.StartedOn
    , ap.Amount
    , isnull(tsp.TrafficSourceName, tsc.TrafficSourceName) as TrafficSourceName
    , iif(ap.ProductNum = 1, N'Новый', N'Повторный') as IsNew
from prd.vw_AllProducts ap
left join client.Client c on c.Id = ap.ClientId
left join mkt.vw_LastTraffiSourceTransitionLog tsc on tsc.ClientId = ap.ClientId
left join mkt.vw_LastTraffiSourceTransitionLog tsp on tsp.ProductId = ap.ProductId
where ap.StartedOn >= '20180901'
    and ap.StartedOn < '20181201'
    
