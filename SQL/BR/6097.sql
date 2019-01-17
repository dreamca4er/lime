drop table if exists #res
;

select *
into #res
from
(
    select 
        crr.id
        , crr.CreatedOn
        , crr.ClientId
        , crr.Score
        , crr.ResultSnapshot
    from cr.CreditRobotResult crr
    where crr.CreatedOn >= '20181211'
        and crr.AnalysisResult = 4
        and crr.Score >= 0.2
        and crr.ResultSnapshot like '%verdictkz=0%'
    
    union all
    
    select 
        crr.id
        , crr.CreatedOn
        , crr.ClientId
        , crr.Score
        , crr.ResultSnapshot
    from cr.CreditRobotResult crr
    where crr.CreatedOn >= '20181211'
        and crr.AnalysisResult = 4
        and crr.Score >= 0.2
        and crr.ResultSnapshot like '%verdictkz=-1%'
) crr
;
/
drop table if exists #c
;

with oj as 
(
    select 
        r.id
        , r.ClientId
        , r.CreatedOn
        , r.score
        , json_value(json_query(oj.value, '$.Messages[0]'), '$.Message') as Verdicts
        , oj.value
        , row_number() over (partition by r.id order by oj."key" desc) as rn
    from #res r
    outer apply openjson(ResultSnapshot) oj
)

,v as 
(
    select
        oj.id
        , oj.clientId
        , oj.CreatedOn
        , oj.score
        , inc.IsNewClient
        , substring(oj.Verdicts, patindex('%VerdictKZ%', oj.Verdicts), patindex('%VerdictDZ%', oj.Verdicts) - patindex('%VerdictKZ%', oj.Verdicts) - 2) as VerdictKZ
        , substring(oj.Verdicts, patindex('%VerdictDZ%', oj.Verdicts), patindex('%Score%', oj.Verdicts) - patindex('%VerdictDZ%', oj.Verdicts) - 2) as VerdictDZ
    from oj
    outer apply
    (
        select json_value(inc.value, '$.IsNewClient') as IsNewClient
        from oj inc
        where inc.rn = 1
            and inc.id = oj.id
    ) inc
    where rn = 2
        and (inc.IsNewClient = 'true' and oj.score >= 0.2
                or
                inc.IsNewClient = 'false' and oj.score >= 0.5)
)

select
    c.ClientId
    , c.LastName
    , c.FirstName
    , c.FatherName
    , c.PhoneNumber
    , iif(c.EmailConfirmed = 1, c.Email, null) as Email
    , v.Score
    , datediff(d, v.CreatedOn, getdate()) as ScoreAge
    , iif(v.VerdictKZ = 'VerdictKZ=-1', N'На ручное', N'Одобрение') as VerdictKZ
    , iif(v.IsNewClient = 'true', 1, 0) as IsNewClient
    , st.*
    , lt.*
    , iif(nst.TariffId < 5, nst.TariffId + 1, 5) as NewST
    , iif(nlt.TariffId < 3, nlt.TariffId + 1, 3) as NewLT
into #c
from v
inner join client.vw_Client c on c.ClientId = v.ClientId
    and c.Status = 3
outer apply
(
    select top 1
        p.Productid as STProductid
        , p.TariffName as STTariffName
    from prd.vw_product p
    where p.ClientId = v.ClientId
        and p.Status >= 2
        and p.ProductType = 1
    order by p.StartedOn desc
) st
outer apply
(
    select top 1
        p.Productid as LTProductid
        , p.TariffName as LTTariffName
    from prd.vw_product p
    where p.ClientId = v.ClientId
        and p.Status >= 2
        and p.ProductType = 2
    order by p.StartedOn desc
) lt
outer apply
(
    select top 1 th.TariffId 
    from client.vw_TariffHistory th
    where th.ClientId = c.clientid
        and th.ProductType = 1
    order by th.CreatedOn desc
) nst
outer apply
(
    select top 1 th.TariffId 
    from client.vw_TariffHistory th
    where th.ClientId = c.clientid
        and th.ProductType = 2
    order by th.CreatedOn desc
) nlt
where not exists 
    (
        select 1 from cr.CreditRobotResult crr2
        where crr2.ClientId = v.ClientId
            and crr2.CreatedOn > v.CreatedOn
    )
;

--select
--    c.*
--    , iif(nst.TariffId < 5, nst.TariffId + 1, 5) as NewST
--    , iif(nlt.TariffId < 3, nlt.TariffId + 1, 3) as NewLT
--from #c c
--outer apply
--(
--    select top 1 th.TariffId 
--    from client.vw_TariffHistory th
--    where th.ClientId = c.clientid
--        and th.ProductType = 1
--    order by th.CreatedOn desc
--) nst
--outer apply
--(
--    select top 1 th.TariffId 
--    from client.vw_TariffHistory th
--    where th.ClientId = c.clientid
--        and th.ProductType = 2
--    order by th.CreatedOn desc
--) nlt
select *
from #c

/
select * -- update th set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from client.UserShortTermTariff th
inner join #c c on c.ClientId = th.ClientId
where th.IsLatest = 1
;

select * -- update th set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from client.UserLongTermTariff th
inner join #c c on c.ClientId = th.ClientId
where th.IsLatest = 1
;

--insert into client.UserShortTermTariff (ClientId,TariffId,CreatedOn,CreatedBy,IsLatest)
select
    ClientId
    , NewST as TariffId
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 1 as IsLatest
from #c
;
--
--insert into client.UserLongTermTariff (ClientId,TariffId,CreatedOn,CreatedBy,IsLatest)
select
    ClientId
    , NewLT as TariffId
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 1 as IsLatest
from #c
;

select *
-- update ush set IsLatest = 0, ModifiedOn = getdate(), ModifiedBy = 0x44
from client.UserStatusHistory ush
inner join #c c on c.ClientId = ush.ClientId
    and ush.IsLatest = 1
;
    
--insert into client.UserStatusHistory (ClientId,Status,IsLatest,CreatedOn,CreatedBy,BlockingPeriod,Substatus)
select
    ClientId
    , 3 as Status
    , 1 as IsLatest
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 30 as BlockingPeriod
    , 304
from #c
;

select *
-- update c set status = 3, SubStatus = 304
from client.Client c
inner join #c cl on cl.ClientId = c.id
;

select
    c.*
    , thst.TariffName
    , thst.MaxAmount
    , thlt.TariffName
    , thlt.MaxAmount
from #c c
inner join client.vw_TariffHistory thst on thst.ClientId = c.ClientId
    and thst.IsLatest = 1
    and thst.ProductType = 1
inner join client.vw_TariffHistory thlt on thlt.ClientId = c.ClientId
    and thlt.IsLatest = 1
    and thlt.ProductType = 2
    
select *
from #c

-- 1108 Lime
-- 1002 mango

--insert dbo.CustomListUsers (CustomlistID,ClientId,DateCreated,CustomField1,CustomField2)
select
    1002 as CustomlistID
    , ClientId
    , getdate() as DateCreated
    , 5 as CustomField1
    , 3 as CustomField2
from #c

select * -- update l set CustomField1 = 5, CustomField2 = 3
from dbo.CustomListUsers l 
where CustomlistID = 1002
/
select *
from client.UserShortTermTariff st
where IsLatest = 1
    and ClientId in (769073, 739252, 659320)
/

select *
from #c c
inner join client
where exists 
(select 1 from prd.vw_product p where c.clientid = p.ClientId and p.CreatedOn >= '20190110')


select
    c.*
    , 
    
    update ustt
    set TariffId = 
    case 
        when nst.TariffId = 12 
        then 12
        else iif(nst.TariffId >= 5, nst.TariffId + 1, 5)
    end
from #c c
inner join client.UserShortTermTariff ustt on ustt.ClientId = c.ClientId
    and ustt.CreatedBy = 0x44
    and ustt.islatest = 1
outer apply
(
    select top 1 th.TariffId 
    from client.vw_TariffHistory th
    where th.ClientId = c.clientid
        and th.ProductType = 1
        and th.IsLatest = 0
    order by th.CreatedOn desc
) nst
/

select
    c.*
    update ustt
    set TariffId = 
    case 
        when nlt.TariffId = 9 
        then 9
        else iif(nlt.TariffId >= 3, nlt.TariffId + 1, 3)
    end
from #c c
inner join client.UserLongTermTariff ustt on ustt.ClientId = c.ClientId
    and ustt.CreatedBy = 0x44
    and ustt.islatest = 1
outer apply
(
    select top 1 th.TariffId 
    from client.vw_TariffHistory th
    where th.ClientId = c.clientid
        and th.ProductType = 2
        and th.IsLatest = 0
    order by th.CreatedOn desc
) nlt
/

select *
from #c c