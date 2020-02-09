merge
prd.operationlog as dst
using (values (@InsertValues))
as src (@InsertColumns)
on dst.id = src.id
when matched then
update set @Fields
;