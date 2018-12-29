declare
    @n nvarchar(100) = N'Уважаемый (ая) [IO]! В связи с достижением вами возраста 45 лет, ваш паспорт подлежит обязательной замене. Уведомляем вас о необходимости предоставить обновленные паспортные данные в Компанию на электронную почту support@lime-zaim.ru для корректной работы личного кабинета и дальнейшего взаимодействия.'
;

drop table if exists #c
;

drop table if exists #n
;

select
    c.id as ClientId
    ,concat
        (
            UPPER(LEFT(c.FirstName,1))+LOWER(SUBSTRING(c.FirstName,2,LEN(c.FirstName))), ' '
            , UPPER(LEFT(c.FatherName,1))+LOWER(SUBSTRING(c.FatherName,2,LEN(c.FatherName)))
        ) as io
    ,c.BirthDate
    ,dateadd(d, datepart(dy, c.BirthDate) - 1, '20180101') as NotifyDate
    ,c.DateRegistered 
into #c
from client.Client c
where datepart(year, BirthDate) = 2018 - 45
    and datepart(dy, BirthDate) <= datepart(dy, cast(getdate() as date))
    and dateadd(d, datepart(dy, c.BirthDate) - 1, '20180101') >= cast(c.DateRegistered as date)
;


select *
into #n
from ecc.Notice n
where exists 
        (
            select 1 from #c c
            where n.ClientId = c.ClientId
                and cast(n.CreatedOn as date) = c.NotifyDate
        )
;

/*insert ecc.Notice
(
    ClientId,Text,CreatedOn,CreatedBy,TemplateUuid,NoticeType,NoticeShowType,AvailableFrom
)
*/
select
    c.ClientId
--    , replace(@n, '[IO]', c.io) as Text
    , c.NotifyDate as CreatedOn
    , cast(0x44 as uniqueidentifier) as CreatedBy
    , '8BB31F67-E722-4F1C-A225-5C3F68CDF910' as TemplateUuid
    , 1 as NoticeType
    , 1 as NoticeShowType
    , '1753-01-01 00:00:00.000' as AvailableFrom
from #c c
where not exists 
    (
        select 1 from #n n
        where n.ClientId = c.ClientId
            and n.text like N'%45 лет%'
    )

;
