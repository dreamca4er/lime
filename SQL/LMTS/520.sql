select
    uc.UserId
    ,fu.Lastname
    ,fu.Firstname
    ,fu.Fathername
    ,fu.mobilephone
    ,fu.emailaddress
    ,ush.Status
from dbo.FrontendUsers fu
inner join dbo.UserCards uc on uc.UserId = fu.id
outer apply
(
    select top 1
        usk.Description as Status
    from dbo.UserStatusHistory ush
    inner join dbo.UserStatusKinds usk on usk.UserStatusKindId = ush.Status
    where ush.UserId = fu.id
        and ush.IsLatest = 1
    order by ush.DateCreated desc
) ush
where not exists 
                    (
                        select 1 from dbo.Lmts520 l
                        where l.passport = uc.Passport
                    )
    and uc.IsFraud = 0
    and uc.IsDied = 0
    and not exists 
                    (
                        select *
                        from dbo.UserBlocksHistory ubh
                        where ubh.UserId = fu.id
                            and ubh.IsLatest = 1
                    )


/*
create clustered index Lmts520_passport_idx on dbo.Lmts520(passport) 

alter table dbo.Lmts520 add primary key(Passport, userid)

ALTER TABLE dbo.Lmts520
  ALTER COLUMN Passport
    VARCHAR(100) COLLATE Cyrillic_General_CI_AS NOT NULL
*/
