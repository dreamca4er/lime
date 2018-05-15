drop table if exists #ip
;

select
    IpAddress
    ,
    replace(replace(replace(replace((
        select distinct c1.UserId
        from dbo.Credits c1
        where c1.IpAddress = c.IpAddress
        order by UserId
        for json auto, without_array_wrapper
    ), '"UserId":', ''), '{', ''), '}', ''), ',', ' ') as users
into dbo.br472
from dbo.Credits c
where Status != 8
group by IpAddress
having count(distinct UserId) > 1
;
/
drop table if exists #tmp
;

select
    fu.id as ClientId
    ,fu.EmailAddress
    ,fu.DateRegistred
    ,ush.status as ClientStatus
    ,isnull(c.CredCnt, 0) as CredCnt
    ,isnull(c.Status, N'Не было кредитов') as CreditStatus
    ,isnull(HadBlock, '-') as HadBlock
    ,ip.users
from dbo.FrontendUsers fu
outer apply
(
    select top 1 ed.Description as Status
    from dbo.UserStatusHistory ush
    inner join dbo.EnumDescriptions ed on ed.Value = ush.Status
        and ed.Name = 'UserStatusKind' 
    where ush.UserId = fu.id
        and ush.IsLatest = 1
) ush
outer apply
(
    select top 1
        cast(right(c.DogovorNumber, 3) as int) as CredCnt
        ,ed.Description as Status
    from dbo.Credits c
    inner join dbo.EnumDescriptions ed on ed.Value = c.Status
        and ed.Name = 'CreditStatus' 
    where c.UserId = fu.id
        and c.Status != 8
    order by c.id desc
) c
outer apply
(
    select top 1 '+' as HadBlock
    from dbo.UserBlocksHistory ubh
    where ubh.UserId = fu.id
) b
outer apply
(
    select distinct ip.IpAddress, users
    from dbo.Credits c
    inner join dbo.br472 ip on ip.IpAddress = c.IpAddress
    where c.userid = fu.id
        and c.status != 8
    for json auto, without_array_wrapper
) as ip(users)
where cast(DateRegistred as date) between '20170101' and '20171231'