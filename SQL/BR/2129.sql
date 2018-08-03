drop table if exists #t
;

with cl as 
(
    select
        ush.UserId as ClientId
    from dbo.UserStatusHistory ush
    where ush.IsLatest = 1
        and ush.Status = 11
        and not exists 
            (
                select 1 from dbo.Credits c2
                where c2.UserId = ush.UserId
                    and c2.Status in (1, 3)
            )
    
    union
    
    select c.UserId
    from dbo.Credits c
    where c.Status = 2
        and not exists 
            (
                select 1 from dbo.Credits c2
                where c2.UserId = c.UserId
                    and c2.id > c.id
            )
    
    union
    
    select 
        c.UserId
    from dbo.Credits c
    outer apply
    (
        select top 1 csh.DateStarted
        from dbo.CreditStatusHistory csh
        where csh.CreditId = c.id
            and csh.Status = 3
        order by csh.DateStarted desc
    ) csh
    where c.Status in (1, 3)
        and (csh.DateStarted is null or datediff(d, csh.DateStarted, getdate()) + 1 <= 7)

)

select
    uc.UserId
    ,fu.Lastname
    ,fu.Firstname
    ,fu.Fathername
    ,fu.mobilephone
    ,fu.emailaddress
    ,uc.Passport
into #t
from dbo.UserCards uc
inner join dbo.FrontendUsers fu on fu.Id = uc.UserId
where uc.IsDied = 0
    and uc.IsFraud = 0
    and uc.IsCourtOrder = 0
    and not exists 
            (
                select 1 from UserBlocksHistory ubh
                where ubh.UserId = uc.UserId
                    and ubh.IsLatest = 1
            )
    and not exists
            (
                select 1 from dbo.UserStatusHistory ush
                where ush.UserId = uc.UserId
                    and ush.IsLatest = 1
                    and ush.Status in (6, 12)
            )
    and fu.MobilePhone like '9%'
    and fu.Firstname not like N'%Тест%'
    and fu.MobilePhone != '9000000000'
    and fu.id in (select ClientId from cl)
;

select *
from #t
where not exists 
        (
            select 1 from "BOR-LIME".Borneo.client."Identity" i
            where i.Number = Passport collate Cyrillic_General_CI_AS
        )