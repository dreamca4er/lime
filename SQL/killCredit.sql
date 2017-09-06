update c
set status = 8
/*
select
    fu.id as clientId
    ,c.id as creditId
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,fu.mobilephone
    ,fu.emailaddress
--into #creds
*/
from dbo.Credits c
inner join dbo.FrontendUsers fu on fu.id = c.userid
where c.Status = 5
    and c.Way = -2
    and cast(c.DateCreated as date) between '20170816' and '20170822'


insert into CreditStatusHistory
SELECT creditId AS CreditId,8 AS Status,getdate() AS DateStarted,getdate() AS DateCreated,1223 AS CreatedByUserId,null AS DateLastUpdated,null AS LastUpdatedByUserId
from #creds


update ush
set islatest = 0
from UserStatusHistory ush
inner join #creds c on c.clientid = ush.userid
    and ush.IsLatest = 1

insert into UserStatusHistory
SELECT clientid as  UserId, 11 AS Status,1 AS IsLatest,getdate() AS DateCreated,1223 AS CreatedByUserId,null AS DateLastUpdated,null AS LastUpdatedByUserId
from #creds

update uai
set uai.state = 11
from UserAdminInformation uai
inner join #creds c on c.clientid = uai.userid
