select *
-- update uc set ClaimValue = 'False'
from sts.UserClaims uc
where userid in
(
    '09F226F2-DC58-4659-BA9B-003D0F57A37A' --	k.balyasnikova	Ксения Балясникова
    , '891113F6-315A-4ED2-96B0-1ACDEE7CF6B2' --	e.izmaylova	Екатерина Измайлова
    , '621EBDBF-07A0-46C4-8B97-1D1DE7C181F8' --	operator	Оператор
    , 'FE5F6C6A-D2D3-40BB-8D02-215BB7F89FB5' --	d.filippov	Дмитрий Филиппов
    , 'A123D504-CBEC-461E-ABBE-4923F6B6C255' --	a.miroshnichenko	Алёна Мирошниченко
    , '0788DF8B-4CED-4D32-A67B-67787B5166E4' --	d.starinok	Дарья Старинок
    , 'FD66A25B-A3A7-44AE-B85A-6BF4477F3AA7' --	a.salihova	Амина Салихова
    , '844C5650-AB2E-4F86-9153-6F2E1135196F' --	a.shelbogasheva	Алина Шелбогашева
    , '53B2B643-6C3D-4004-924F-72D6C08A6615' --	a.natochina	Алина Наточина
    , '91952395-8CCC-4A5C-A55A-76C764C57147' --	s.evsjutin	Станислав Евсютин
    , '445F76AF-7E0F-4A20-A439-B718A65A694C' --	m.maksimov	Максим Максимов
    , '632AB4C4-1D08-413D-9BA7-CD16F0EC9D21' --	a.bayankina	Айсулу Баянкина
    , '8EA2A4D0-D439-4D34-A1F8-E2CFBC7E9DA4' --	t.ilyina	Татьяна Ильина
    , '12BAD1B5-40CC-4C29-A900-E9A228D36726' --	a.sakharov	Александр Сахаров
)
    and ClaimType = 'is_enabled'
    
/



s.peregontseva1
a.matrosova1
SvetlanaB1
a.borovetskaya1
m.chochieva1