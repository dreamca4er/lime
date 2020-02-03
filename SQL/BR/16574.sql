select count(*), count(p.Uid)
-- update pm set pm.Uid = p.Uid
from crh.ProductMetadata pm
inner join prd.Product p on p.Id = pm.ProductId
where pm.Uid is null

