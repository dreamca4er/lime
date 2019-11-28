drop table if exists #users
;

select 
    v.FullName
    , isnull(a.Name, concat(json_value(jf.JsonedFullName, '$[1]'), ' ', json_value(jf.JsonedFullName, '$[0]'))) as ShortName
    , a.Id as UserId
    , v.GroupName
    , g.Id as GroupId 
    , isnull(a.Roles, '') as Position
into #users
from
(
    values
    (N'Андренкова Елена Александровна', N'Клиентский отдел')
    , (N'Евсютин Станислав Владимирович', N'Клиентский отдел')
    , (N'Измайлова Екатерина Сергеевна', N'Клиентский отдел')
    , (N'Мирошниченко Алёна Игоревна', N'Клиентский отдел')
    , (N'Салихова Амина Сираджеддиновна', N'Клиентский отдел')
    , (N'Сахаров Александр Юрьевич', N'Клиентский отдел')
    , (N'Шелбогашева Алина Владимировна', N'Клиентский отдел')
    , (N'Мухаметшина Дарья Анатольевна', N'Клиентский отдел')
    , (N'Касьянова Кристина Евгеньевна', N'Клиентский отдел')
    , (N'Подъячева Наталья Сергеевна', N'Клиентский отдел')
    , (N'Сударев Сергей Игоревич', N'Клиентский отдел')
    , (N'Толок Евгения Борисовна', N'Клиентский отдел')
    , (N'Магута Кристина Сергеевна', N'Клиентский отдел')
    , (N'Богданова Юлия Михайловна', N'Клиентский отдел')
    , (N'Краснощекова Алина Сергеевна', N'Отдел Комплаенс')
    , (N'Введенская Александра Дмитриевна', N'Отдел Комплаенс')
    , (N'Мироненко Олеся Александровна', N'Отдел Комплаенс')
    , (N'Поцелуева Ольга Сергеевна', N'Отдел Комплаенс')
) v(FullName, GroupName)
inner join lgl."Group" g on g.Name = v.GroupName
outer apply
(
    select json_query('["' + replace(v.FullName, ' ', '","') +'"]') as JsonedFullName
) jf
left join sts.vw_admins a on a.Name = 
    concat(json_value(jf.JsonedFullName, '$[1]'), ' ', json_value(jf.JsonedFullName, '$[0]'))
GO

insert lgl.Person
(
    FullName,ShortName,Position,UserId,CreatedOn,CreatedBy
)
select
    FullName
    , ShortName
    , Position
    , UserId
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
from #users u
where not exists
    (
        select 1 from lgl.Person p
        where p.UserId = u.UserId 
            or p.FullName = u.FullName
                and p.UserId is null
    )
GO

insert lgl.PersonGroup
(
    PersonId,GroupId,Role
)
select
    p.Id as PersonId
    , u.GroupId
    , 1 as Role
from lgl.Person p
inner join #users u on u.Fullname = p.Fullname
where not exists
    (
        select 1 from lgl.PersonGroup pg
        where pg.PersonId = p.id
    )
