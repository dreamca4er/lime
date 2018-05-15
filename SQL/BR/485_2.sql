with a as 
(
    select distinct p.ClientId, b.IpAddress
    from dbo.br472 b
    inner join prd.Product p on p.id = b.CreditId
    inner join client.Client c on c.id = p.ClientId
    where c.DateRegistered >= '20180101'
    
    union
    
    select distinct c.id, c.IpAddress
    from client.Client c
    where c.DateRegistered >= '20180101'
)

select 
    a.IpAddress
    ,
    replace(replace(replace((
        select distinct a1.ClientId
        from a a1
        where a1.IpAddress = a.IpAddress
        for json auto, without_array_wrapper
    ), '"ClientId":', ''), '{', ''), '}', '') as users
into dbo.br485
from a
group by a.IpAddress
having count(distinct a.ClientId) > 1
;
select len(users),count(*) 
from dbo.br485 b
group by len(users)



create index IX_br485_IpAddress on br485(IpAddress)
drop table br485_3
create table br485_3
(
    ClientId int
    ,ipaddress nvarchar(255)
    ,users nvarchar(1500)
)
insert into br485_3
select distinct a.ClientId, ip.ipaddress, ip.users
from dbo.br485_1 a
inner join dbo.br485 ip on a.IpAddress = ip.IpAddress

select max(len(ip.users))
from dbo.br485 ip 
/
select
    c.clientid
    ,c.Email
    ,c.DateRegistered
    ,c.substatusName as ClientStatus
    ,p.ProductCount    
    ,isnull(pc.status, N'Не было кредитов') as ProductStatus
    ,isnull(b.HadBlocks, '-') as HadBlocks
--    ,ip.users
into dbo.br485_2
from client.vw_Client c
outer apply
(
    select count(*) as ProductCount
    from prd.vw_Product p
    where p.clientId = c.clientid
        and p.status > 2
) p
outer apply
(
    select top 1 '+' as HadBlocks
    from client.UserStatusHistory ush
    where ush.ClientId = c.clientid
        and ush.BlockingPeriod > 0
) b
outer apply
(
    select top 1 p.statusName as status
    from prd.vw_Product p
    where p.clientId = c.clientid
        and p.status > 2
    order by p.productid desc
) pc
--outer apply
--(
--    select distinct ip.IpAddress, ip.users
--    from dbo.br485_1 a
--    inner join dbo.br485 ip on a.IpAddress = ip.IpAddress
--    where a.ClientId = c.ClientId
--    for json auto, without_array_wrapper
--) as ip(users)
where c.DateRegistered >= '20180101'

/

select
    b2.*
    ,
    (
        select distinct b3.ipaddress, b3.users
        from dbo.br485_3 b3
        where b3.clientid = b2.clientid
        for json auto, without_array_wrapper
        
    )
from dbo.br485_2 b2


