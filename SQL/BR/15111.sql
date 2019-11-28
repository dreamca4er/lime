drop table if exists #cl
;

with cl as 
(
    select *
    from
    (
        values
        (2185864, 0.956)
        , (2378127, 0.93)
        , (3603358, 0.922)
        , (2924115, 0.903)
        , (2470262, 0.892)
        , (2143142, 0.888)
        , (1381248, 0.878)
        , (859246, 0.869)
        , (2480945, 0.856)
        , (2542150, 0.854)
        , (3397405, 0.849)
        , (3190133, 0.847)
        , (2583361, 0.844)
        , (2173763, 0.841)
        , (2212598, 0.84)
        , (2606747, 0.838)
        , (842660, 0.837)
        , (3043518, 0.833)
        , (3185323, 0.833)
        , (3465450, 0.824)
        , (2983534, 0.823)
        , (3073107, 0.823)
        , (2682780, 0.823)
        , (3697840, 0.815)
        , (2099803, 0.81)
        , (3201440, 0.808)
        , (2922554, 0.808)
        , (2731075, 0.802)
        , (3526773, 0.801)
        , (3245328, 0.796)
        , (2253313, 0.789)
        , (3273160, 0.789)
        , (3273561, 0.786)
        , (3194313, 0.786)
        , (2265220, 0.784)
        , (3439495, 0.782)
        , (2996517, 0.78)
        , (1658769, 0.772)
        , (1759567, 0.766)
        , (3018315, 0.759)
        , (2466813, 0.757)
        , (2594068, 0.745)
        , (3286599, 0.745)
        , (3188526, 0.744)
        , (3203119, 0.739)
        , (2497800, 0.739)
        , (857199, 0.737)
        , (2826498, 0.735)
        , (3400013, 0.734)
        , (3468614, 0.731)
        , (2406206, 0.731)
        , (2030268, 0.73)
        , (3040550, 0.73)
        , (3071960, 0.729)
        , (2297177, 0.727)
        , (2973721, 0.727)
        , (3324363, 0.726)
        , (3148214, 0.724)
        , (2939366, 0.722)
        , (3619938, 0.721)
        , (2570931, 0.719)
        , (2040597, 0.716)
        , (3400513, 0.713)
        , (966350, 0.713)
        , (541196, 0.712)
        , (2512567, 0.712)
        , (1974943, 0.712)
        , (3182746, 0.704)
        , (3534561, 0.702)
        , (3477962, 0.701)
        , (1897509, 0.7)
        , (3495417, 0.699)
        , (3305920, 0.697)
        , (2467633, 0.696)
        , (3655605, 0.694)
        , (3444660, 0.692)
        , (2213111, 0.691)
        , (3051959, 0.691)
        , (3021715, 0.69)
        , (3206061, 0.688)
        , (1961159, 0.687)
        , (3134049, 0.686)
        , (1497309, 0.686)
        , (3538676, 0.682)
        , (2612000, 0.677)
        , (2246910, 0.677)
        , (2933771, 0.675)
        , (2289793, 0.674)
        , (1825403, 0.674)
        , (3233949, 0.673)
        , (2180232, 0.671)
        , (3048408, 0.671)
        , (3507430, 0.668)
        , (1349253, 0.667)
        , (3655872, 0.665)
        , (2622215, 0.664)
        , (2327985, 0.66)
        , (2530623, 0.654)
        , (3036600, 0.654)
        , (2603706, 0.654)
        , (3178898, 0.653)
        , (2521025, 0.649)
        , (2434951, 0.646)
        , (3031025, 0.646)
        , (3555360, 0.644)
        , (3547812, 0.643)
        , (1838290, 0.643)
        , (3435138, 0.641)
        , (2858356, 0.64)
        , (3561429, 0.639)
        , (2493291, 0.639)
        , (2922263, 0.638)
        , (3516336, 0.638)
        , (2600766, 0.636)
        , (3310361, 0.636)
        , (2607914, 0.636)
        , (1845862, 0.63)
        , (1074919, 0.628)
        , (3225434, 0.626)
        , (2184428, 0.626)
        , (3875720, 0.625)
        , (2927746, 0.624)
        , (3435813, 0.624)
        , (2784767, 0.623)
        , (3327576, 0.622)
        , (2426615, 0.62)
        , (3144122, 0.619)
        , (3016262, 0.618)
        , (2744606, 0.617)
        , (1358412, 0.617)
        , (3258186, 0.616)
        , (2805662, 0.615)
        , (2413003, 0.615)
        , (2604701, 0.613)
        , (2501348, 0.613)
        , (3018012, 0.612)
        , (2565518, 0.609)
        , (3336182, 0.609)
        , (3032395, 0.609)
        , (2106814, 0.609)
        , (3138681, 0.608)
        , (3154318, 0.608)
        , (2923082, 0.608)
        , (1232224, 0.607)
        , (3478963, 0.605)
        , (2901378, 0.604)
        , (2504695, 0.604)
        , (1984963, 0.603)
        , (3600821, 0.601)
        , (1722398, 0.601)
        , (2071018, 0.6)
        , (3596465, 0.914)
    ) c(ClientId, Score)
)

select *
into #cl
from cl

select c.AdminProcessingFlag
-- update c set c.AdminProcessingFlag = 4
from #cl cl
inner join client.Client c on c.id = cl.ClientId
/
select
    cl.*
    , c.LastName
    , c.FirstName
    , c.FatherName
    , iif(c.EmailConfirmed = 1, c.Email, null) as Email
    , c.PhoneNumber
    , st.TariffName as st
    , st.CreatedOn as stdate
    , lt.TariffName as lt
    , lt.CreatedOn as ltdate
    , c.substatusName
from #cl cl
inner join client.vw_Client c on c.CLientId = cl.CLientId
left join client.vw_TariffHistory st on st.ClientId = c.clientid
    and st.IsLatest = 1
    and st.ProductType = 1
left join client.vw_TariffHistory lt on lt.ClientId = c.clientid
    and lt.IsLatest = 1
    and lt.ProductType = 2
/*
insert cr.CreditRobotResult
(
    ClientId,CreatedOn,AnalysisResult,Score,ShortTermScore,LongTermScore,ScoringPurpose
)
select
    cl.ClientId
    , '20191017 09:00'
    , 1
    , cl.Score
    , cl.Score
    , cl.Score
    , 3 as ScoringPurpose
from cl
where not exists
    (
        select 1 from cr.CreditRobotResult crr
        where crr.clientid = cl.ClientId
            and crr.createdon >= '20191017'
    )
;

insert into client.UserShortTermTariff (ClientId,TariffId,CreatedOn,CreatedBy,IsLatest)
select
    ClientId
    , 5
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 1 as IsLatest
from #cl

insert client.UserProductBlockHistory
(
    ClientId,ProductType,BlockingPeriod,CreatedOn,CreatedBy
)
select
    cl.ClientId
    , 1
    , 0
    , getdate()
    , 0x44
from #cl cl
inner join client.UserProductBlock upb on upb.ClientId = cl.ClientId
where ProductType = 1

delete upb
from #cl cl
inner join client.UserProductBlock upb on upb.ClientId = cl.ClientId
where ProductType = 1

update ush set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from #cl cl
inner join client.UserStatusHistory ush on ush.ClientId = cl.ClientId
where ush.IsLatest = 1

insert into client.UserStatusHistory (ClientId,Status,IsLatest,CreatedOn,CreatedBy,BlockingPeriod,Substatus)
select
    ClientId
    , 2
    , 1 as IsLatest
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 0
    , 203
from #cl

update c set Status = 2, Substatus = 203
from #cl cl
inner join client.Client c on c.id = cl.CLientId 

update lt set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from #cl cl
inner join client.UserLongTermTariff lt on lt.ClientId = cl.ClientId
    and lt.IsLatest = 1
    
insert into client.UserProductBlock
(
    ClientId,ProductType,BlockingPeriod,CreatedOn,CreatedBy
)
select
    cl.ClientId
    , 2 as ProductType
    , 30 as BlockingPeriod
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
from #cl cl
where not exists
    (
        select 1 from client.UserProductBlock pbh
        where pbh.ClientId = cl.ClientId
            and pbh.ProductType = 2
    )
  
update stt set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from #cl cl
inner join client.UserShortTermTariff stt on stt.ClientId = cl.clientid
    and stt.IsLatest = 1
where not exists
    (
        select 1 from client.UserShortTermTariff st
        where st.ClientId = cl.ClientId
            and st.IsLatest = 1
            and st.TariffId = 5
    )

insert into client.UserShortTermTariff (ClientId,TariffId,CreatedOn,CreatedBy,IsLatest)
select
    ClientId
    , 5
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 1 as IsLatest
from #cl cl
where not exists
    (
        select 1 from client.UserShortTermTariff st
        where st.ClientId = cl.ClientId
            and st.IsLatest = 1
            and st.TariffId = 5
    )

delete cl
from #cl cl
where exists
    (
        select 1 from prd.vw_product p
        where p.ClientId = cl.ClientId
            and p.CreatedOn >= '20191017'
    )

update ush set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from #cl cl
inner join client.UserStatusHistory ush on ush.ClientId = cl.ClientId
where ush.IsLatest = 1
    and ush.Substatus != 203


insert into client.UserStatusHistory (ClientId,Status,IsLatest,CreatedOn,CreatedBy,BlockingPeriod,Substatus)
select
    ClientId
    , 2
    , 1 as IsLatest
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 0
    , 203
from #cl cl
inner join client.client c on c.id = cl.ClientId
where c.Substatus != 203

update c set Status = 2, Substatus = 203
from #cl cl
inner join client.Client c on c.id = cl.CLientId 
*/
/


select
    cl.*
    , c.LastName
    , c.FirstName
    , c.FatherName
    , iif(c.EmailConfirmed = 1, c.Email, null) as Email
    , c.PhoneNumber
    , st.TariffName as st
    , st.CreatedOn as stdate
    , lt.TariffName as lt
    , lt.CreatedOn as ltdate
    , c.substatusName
    , pbs.BlockingPeriod as stblock
    , pbl.BlockingPeriod as ltblock
from #cl cl
left join client.vw_Client c on c.ClientId = cl.ClientId
left join client.UserStatusHistory ush on ush.ClientId = cl.ClientId
    and ush.IsLatest = 1
left join client.vw_TariffHistory st on st.ClientId = cl.clientid
    and st.IsLatest = 1
    and st.ProductType = 1
left join client.vw_TariffHistory lt on lt.ClientId = cl.clientid
    and lt.IsLatest = 1
    and lt.ProductType = 2
left join client.UserProductBlock pbs on pbs.ClientId = cl.ClientId
    and pbs.ProductType = 1
left join client.UserProductBlock pbl on pbl.ClientId = cl.ClientId
    and pbl.ProductType = 2

insert client.UserProductBlockHistory
(
    ClientId,ProductType,BlockingPeriod,CreatedOn,CreatedBy
)
select
    cl.ClientId
    , 1
    , 0
    , getdate()
    , 0x44
from #cl cl
inner join client.UserProductBlock upb on upb.ClientId = cl.ClientId
where ProductType = 1
    and cl.ClientId = 2185864

delete upb
from #cl cl
inner join client.UserProductBlock upb on upb.ClientId = cl.ClientId
where ProductType = 1
    and cl.ClientId = 2185864
