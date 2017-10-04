use LimeZaim_Website;
GO
select
    cfu.UserId
    ,cfu.rate_ed_FinBurden as FinBurdern
    ,cfu.num_ed_ClosedMLAmt as AvgMloan
into ##user
--
from dbo.FrontendUsers fu
inner join dbo.UserStatusHistory ush on ush.UserId = fu.ID
    and ush.IsLatest = 1
    and ush.status = 6
inner join dbo.UserBlocksHistory ubh on ubh.UserId = fu.id
    and ubh.IsLatest = 1
    and ubh.Period != 3652
cross apply
(
    select top 1
        *
    from dbo.checkForUnblock cfu
    where cast(cfu.UserID as int) = fu.id
    order by cfu.id desc
) cfu


/*
insert into dbo.UserCustomLists
SELECT 18 AS CustomlistID, UserId,getdate(),null AS CustomField1,null AS CustomField2
from ##user

select *
from dbo.UserCustomLists
where customlistid = 18
*/
/

; with fin as 
(
    select *
    from (values (-1,17,6), (14,34,5), (34,50,4)
            , (50,66,3), (66,83,2), (83,100,1)
        ) as fb (minx, maxx, StepOrder)
)
select u.UserID
    , u.FinBurdern
    , u.AvgMLoan
    , MIN(t.[Order]) as mloanStep
    , MIN(f.StepOrder) as finStep
into #outUser -- drop table #outUser
from ##user u
left join dbo.TariffSteps t on t.TariffID = 2
    and t.[Order] <= 6
    and ( u.AvgMloan between 1000 and t.MaxAmount
        or u.AvgMLoan > 2000 and t.[Order] = 6
        )
left join fin f on u.AvgMLoan = 0
    and u.FinBurdern > f.minx
    and u.FinBurdern <= f.maxx
where 1=1
group by u.UserID
    , u.FinBurdern
    , u.AvgMLoan
order by 3
/

-- подготовка итогового датасета: клиент, шаг, статус. берем только тех, кто в статусе Нужен тариф
select u.UserID
    , t.StepId
    , us.Status
into #finalds   -- drop table #finalds  -- select * from #finalds 
from #outUser u
inner join dbo.vw_tariffSteps t on t.TariffId = 2
    and t.StepOrder = ISNULL(u.mloanStep, u.finStep)
inner join dbo.UserStatusHistory us on us.UserID = u.UserId
    and us.IsLatest = 1
--where us.Status IN (9,10)

/
select *
from #finalds
/

-- сбрасываем последний статус
update h
set h.IsLatest = 0
from #finalds f
inner join dbo.UserStatusHistory h on h.islatest = 1
    and h.UserId = f.UserID

-- установим новый статус
insert dbo.UserStatusHistory (UserId, Status, Islatest, dateCreated, CreatedByUserId)
select f.UserId, 11, 1, getdate(), 2
from #finalds f

update h set h.islatest = 0
from dbo.UserBlocksHistory h
inner join #finalds f on f.UserId = h.UserID and h.Islatest = 1


-- сбросим предыдущий тариф КЗ
update h
set h.IsLatest = 0 -- select top 10 h.*
from dbo.UserTariffHistory h
inner join dbo.vw_TariffSteps ts on ts.StepID = h.StepID
    and ts.TariffType = 1
inner join #finalds f on f.UserId = h.UserID
where h.IsLatest = 1

-- устанавливаем новый тариф КЗ по правилам скоринга
insert dbo.UserTariffHistory (UserID, StepId, DateCreated, CreatedByUserId, RequestId, Islatest)
select f.UserId, f.StepId, getdate(), 2, 0, 1
from #finalds f

-- обновляем uai, чтоб в админке корректно показывало
update uai
set uai.State = us.State
    , uai.Stepname = t.TariffName +'\' + t.StepName 
        + ISNULL( N';' + tL.TariffName +'\' + tL.StepName, '')
/*
select uai.UserID 
    , uai.State
    , us.State
    , uai.Stepname
    , t.TariffName +'\' + t.StepName 
        + ISNULL( N';' + tL.TariffName +'\' + tL.StepName, '') as StepName */
from dbo.UserAdminInformation uai
inner join #finalds f on f.userId = uai.UserId
inner join dbo.vw_UserStatuses us on us.id = f.UserID
inner join dbo.vw_UserTariffs ut on ut.UserId = f.UserId
inner join dbo.vw_TariffSteps t on t.StepID = ut.StepID
    and t.TariffId = 2
left join dbo.vw_UserTariffs utL on utl.UserId = f.UserId
    and utL.Type = 2
left join dbo.vw_TariffSteps tL on tL.StepId = utL.StepId

select fu.id
    , fu.Lastname
    , fu.Firstname
    , fu.Fathername
    , fu.Mobilephone
    , fu.EmailAddress
    , t.StepName -- select top 100 
from dbo.FrontendUsers fu
inner join #finalds f on f.UserId = fu.ID
inner join dbo.vw_UserTariffs ut on ut.UserId = f.UserId
inner join dbo.vw_TariffSteps t on t.StepID = ut.StepID
    and t.TariffId = 2
