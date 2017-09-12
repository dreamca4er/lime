select 
--    count(*)
    fu.id as clientId
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,fu.mobilephone
    ,fu.emailaddress
from dbo.vw_UserStatuses us
inner join dbo.FrontendUsers fu on fu.Id = us.id
inner join dbo.UserAdminInformation uai on uai.UserId = us.Id
    and isnull(uai.LastCreditStatus, 0) != 3
left join dbo.UserCards uc on uc.UserId = fu.id
where us.BlockedPeriod is null
    and us.State != 12
    and not exists (
                        select 1 from dbo.lmts367Konga 
                        where uc.Passport = lmts367Konga.Passport
                    )
    and not exists (
                        select 1 from dbo.lmts367mango
                        where uc.Passport = lmts367mango.Passport
                    )
   


--SELECT
--    col.name, col.collation_name
--FROM 
--    sys.columns col
--WHERE
--    object_id = OBJECT_ID('UserCards')
--    and col.name = 'Passport'
--
--ALTER TABLE dbo.lmts367mango
--  ALTER COLUMN Passport
--    VARCHAR(100) COLLATE Cyrillic_General_CI_AS NOT NULL


--select
--    fu.id as clientid
--    ,uc.Passport
--from dbo.FrontendUsers fu
--inner join dbo.UserAdminInformation uai on uai.UserId = fu.id
--inner join dbo.UserCards uc on uc.UserId = fu.id
--cross apply
--(
--    select top 1
--        c.Status
--    from dbo.Credits c
--    where c.UserId = fu.id
--        and c.Status != 8
--    order by c.id desc
--) credInfo
--where credInfo.Status in (1, 2)

/

select
--    count(*)
    fu.id as clientId
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,fu.mobilephone
    ,fu.emailaddress
    ,fu.DateRegistred
    ,datepart(yyyy, fu.DateRegistred)
from dbo.vw_UserStatuses us
inner join dbo.FrontendUsers fu on fu.Id = us.id
where us.State = 11
    and datepart(yyyy, fu.DateRegistred) = 2017
