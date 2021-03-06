select
	u.id
	,concat(u.lastname, ' ', u.firstname, ' ', u.fathername) as fio
	,u.mobilephone
	,u.emailaddress
from dbo.frontendusers u
inner join dbo.usercards uc on uc.userid = u.id
inner join dbo.userstatushistory ush on ush.userid = u.id
	and ush.islatest = 1
where uc.[IsFraud] = 0
	and uc.[IsDied] = 0 
	and ush.status not in (6, 12)
	and not exists 
			(
				select 1 from [dbo].[BorneoLimeBlocked] dbl
				where dbl.phonenumber = '7' + u.mobilephone
			)
				and not exists 
			(
				select 1 from [dbo].[BorneoLimeBlocked] dbl
				where dbl.passport = uc.passport 
				collate SQL_Latin1_General_CP1_CI_AS
			)
	and not exists 
				(
					select 1 from dbo.credits c
					where c.userid = u.id
						and c.status in (1, 3, 5)
				)
    and u.lastname not like N'%тест%'
    and u.firstname not like N'%тест%'
    and (u.Fathername not like N'%тест%' or u.Fathername is null or u.Fathername = '')
    and MobilePhone not like '0%'
