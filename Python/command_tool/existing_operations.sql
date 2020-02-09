select id, CommandType, OperationFullName, CommandSnapshot
from prd.OperationLog
where ProductId = @ProductId
    and CommandType in (@CommandTypes)
order by CommandType, json_value(CommandSnapshot, '$.OperationDate')