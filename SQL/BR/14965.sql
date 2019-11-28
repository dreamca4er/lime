declare
    @query nvarchar(1000) = 
    '
    select
        p.ClientId
        , concat(c.LastName, char(32), c.FirstName, char(32), c.FatherName) as fio
        , i.Number
        , p.Productid
        , p.ContractNumber
        , p.Amount
        , p.ContractPayDay
        , #servername
        , cb.*
    from borneo.prd.vw_product p
    left join borneo.client."Identity" i on i.ClientId = p.ClientId
    left join borneo.client.Client c on c.id = p.ClientId
    outer apply
    (
        select top 1
            (cb.OverdueAmount + cb.OverdueRestructAmount) * -1 as OverdueAmount
            , (cb.OverduePercent + cb.OverdueRestructPercent) * -1 as OverduePercent
            , cb.Fine * -1 as Fine
        from bi.CreditBalance cb
        where cb.ProductId = p.Productid
            and cb.InfoType = #infotype
        order by cb.DateOperation desc
    ) cb
    where p.Status = 4
    '
;

declare
    @openquery nvarchar(1000) = 'select * from openquery(#server, ''' + @query + ''')'
;

drop table if exists #clients
;

create table #clients
(
    ClientId int
    , Fio nvarchar(100)
    , Passport nvarchar(100)
    , Productid int
    , ContractNumber nvarchar(10)
    , Amount numeric(18, 2)
    , ContractPayDay date
    , Project nvarchar(10)
    , OverdueAmount numeric(18, 2)
    , OverduePercent numeric(18, 2)
    , Fine numeric(18, 2)
)
;

declare @WorkingQuery nvarchar(1000) = replace(replace(@query, '#servername', '''lime'''), '#infotype', '''debt''')
;

insert into #clients
exec sp_executesql @WorkingQuery

set @WorkingQuery = replace(replace(replace(@openquery
                        , '#servername', '''''konga''''')
                        , '#server', '"bor-konga-db"')
                        , '#infotype', '''''debt''''') 
insert into #clients
exec sp_executesql @WorkingQuery

set @WorkingQuery = replace(replace(replace(@openquery
                        , '#servername', '''''mango''''')
                        , '#server', '"bor-mango-db"') 
                        , '#infotype', '''''debt''''')
insert into #clients
exec sp_executesql @WorkingQuery


create index IX_Passport_clients on #clients(Passport)
;
/

select top 10 *
from #clients c
where exists
    (
        select 1 from #clients c2
        where c2.Passport = c.Passport
        group by c2.Passport
        having count(*) > 1
    )
order by c.Passport, c.Project, c.ClientId
/

select *
from collector.EnumStrategyConditionType