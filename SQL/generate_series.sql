declare @exponent integer = 
(
select
  ceiling(log(datediff(d, min(DateRegistred), cast(getdate() as date)) + 1, 10)) as value
from FrontendUsers fu
),
  @cnt integer = 0,
  @query varchar(max) = ''
;


while @cnt < @exponent - 1
begin
  set @query = @query + ' cross join nums n' + cast(@cnt as varchar);
  set @cnt = @cnt + 1;
end;

exec ('
with nums as (
select 1 as a union all select 1 union all
select 1 as a union all select 1 union all
select 1 as a union all select 1 union all
select 1 as a union all select 1 union all
select 1 as a union all select 1
)

,generated as (select n.a from nums n' + @query + ')

select row_number() over (order by a) as rn
from generated
'
)
