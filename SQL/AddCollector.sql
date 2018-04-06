insert into col.CollectorGroup
 (
    Name, CollectorId
 )
select 'B', '635f9f7e-27ee-43d2-bf6f-5f747ceaa4ed'

select *
from sts.vw_admins


select * -- update op set IsDeleted = 1 
from col.OverdueProduct op
where op.CollectorId = 'c7456e37-160a-4f15-9c51-661ca0ee8f87'
    and op.IsDeleted = 0

select * -- delete
from col.CollectorGroup
where CollectorId = 'c7456e37-160a-4f15-9c51-661ca0ee8f87'