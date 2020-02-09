select top 1
    CommandType
    , OperationFullName
    , CommandSnapshot
from prd.OperationLog ol
where ol.CommandType = @CommandType
order by ol.Id