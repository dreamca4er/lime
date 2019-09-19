drop table if exists stage.dbo.br13852house
;

create table stage.dbo.br13852house
(
    id int not null primary key
    , House nvarchar(100)
    , Block nvarchar(100)
)
;
--alter table stage.dbo.br13852house add primary key (id)
/
insert stage.dbo.br13852house
select
    a.id
    , json_value(a.Data, '$.data.house') as House
    , json_value(a.Data, '$.data.block') as Block
from Borneo.client.Address a
where json_value(a.Data, '$.data.house') not like '[0-9]%'
    or json_value(a.Data, '$.data.block') not like '[0-9]%'
    or json_value(a.Data, '$.data.house') like '% %'
    or json_value(a.Data, '$.data.block') like '% %'
    
/
create index IX_dbo_br13852house_House on stage.dbo.br13852house(House)
create index IX_dbo_br13852house_Block on stage.dbo.br13852house(Block)
/
drop table if exists stage.dbo.br13852HouseParsed
;

select 
    a.*
    , rtrim(ltrim(isnull(nullif(s3.NoDashes, ''), '0'))) as FinalNums
into stage.dbo.br13852HouseParsed
from 
(
    select  
        house as obj
    from stage.dbo.br13852house
    
    union 
    
    select 
        Block
    from stage.dbo.br13852house
) a
outer apply
(
    select 
        substring(obj, patindex('%[0-9]%', obj), len(obj) - patindex('%[0-9]%', obj) + 1) as StartsWithNum
) s
outer apply
(
    select 
        case  
            when patindex('% %', s.StartsWithNum) = 0
            then s.StartsWithNum
            else substring(s.StartsWithNum, 1, patindex('% %', s.StartsWithNum))
        end as NoSpaces
) s2
outer apply
(
    select replace(s2.NoSpaces, '-', iif(s2.NoSpaces like '%-[0-9]%', '/', '')) as NoDashes
) s3

create clustered index IX_dbo_br13852HouseParsed on stage.dbo.br13852HouseParsed (obj)
/

select hp.*
-- update top (1000) a set a.Data = json_modify(a.Data, '$.data.house_no_type', isnull(hp.FinalNums, h.House)), ModifiedBy = 0x1385201

from Borneo.client.Address a
inner join stage.dbo.br13852house h on h.id = a.Id
inner join stage.dbo.br13852HouseParsed hp on hp.obj = h.House
where (ModifiedBy is null or MOdifiedBY != 0x1385201)

    /

select top 10 *
from client.vw_GetAddress
--where ClientId = 3891606
select top 10 *
from client.vw_Address
--where ClientId = 3891606

select *
-- update top (1000) a set a.Data = json_modify(a.Data, '$.data.house_no_type', isnull(hp.FinalNums, h.House)), ModifiedBy = 0x1385201
from Borneo.client.Address a
--inner join stage.dbo.br13852house h on h.id = a.Id
--inner join stage.dbo.br13852HouseParsed hp on hp.obj = h.House
where isnull(json_value(a.Data, '$.data.house_no_type'), json_value(a.Data, '$.data.house')) not like '[0-9]%'

/
