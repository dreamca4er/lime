/*
43	Иркутская Область
1197	Иркутский Район
4752	г Иркутск
*/
select
  cast(fu.DateRegistred as date) as DateRegistered
 ,fu.id as UserId
 ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
 ,case when uai.FactCityId = 4752 then N'Город Иркутск'
    else N'Иркутская область'
  end as factAddress
 ,cc.cnt as creditsCnt
 ,case when os.UserId is not null then N'Да'
       else N'Нет'
  end as haveOverdue
from dbo.UserAdminInformation uai
inner join dbo.Locations l on l.Id = uai.FactCityId
inner join dbo.FrontendUsers fu on fu.Id = uai.UserId
outer apply 
(
  select top 1 ush.UserId
  from dbo.UserStatusHistory ush
  where ush.UserId = fu.id
    and ush.Status = 3
    and ush.IsLatest = 1
    and ush.UserId = fu.id
) os 
outer apply
(
  select count(*) as cnt
  from dbo.Credits c
  where c.UserId = fu.Id
    and c.Status not in (5, 8)
) cc
where uai.FactCityId = 4752
  or uai.FactRegion = N'Иркутская Область'

