select
    uc.UserId
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,fu.mobilephone
    ,fu.emailaddress
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
    and exists 
            (
                select *
                from dbo.Credits c
                where c.UserId = uc.UserId
                    and c.Status = 2
                group by c.UserId
                having count(*) > 2
            )
    and exists
            (
                select 1 from dbo.UserStatusHistory ush
                where ush.UserId = uc.UserId
                    and ush.IsLatest = 1
                    and ush.Status = 11
            )

