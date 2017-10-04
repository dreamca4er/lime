use LimeZaim_Website;
GO
/*
drop table #usr
drop table #outUser
drop table #finalds     */
/*
select *
into #usr -- drop table #usr
from (
select	4,198182,51.8518518519,15368.1818	union all
select	5,219104,82.3529411765,6735.4166	union all
select	7,393887,43.5185185185,8409.0909	union all
select	8,418555,29.6296296296,3200.0	union all
select	9,447618,52.9411764706,4014.6341	union all
select	11,470634,51.8518518519,3105.0	union all
select	12,478471,51.8518518519,5243.1818	union all
select	13,480044,54.6296296296,4654.8387	union all
select	15,502328,54.6296296296,10959.2592	union all
select	16,517184,12.962962963,6161.0389	union all
select	17,517296,10.1851851852,4822.2222	union all
select	18,530514,54.6296296296,16163.4042	union all
select	19,614383,70.3703703704,7116.6666	union all
select	20,621955,30.5555555556,4178.5714	union all
select	23,645633,43.5185185185,16778.5714	union all
select	25,686282,43.5185185185,13829.7384	union all
select	26,735876,62.037037037,11930.7692	union all
select	27,741755,40.7407407407,16910.7142	union all
select	30,752658,82.3529411765,16123.0769	union all
select	32,756143,54.6296296296,5063.5135	union all
select	33,765517,43.5185185185,4142.8571	union all
select	34,766459,54.6296296296,15302.3255	union all
select	35,806363,54.6296296296,6375.0	union all
select	41,850485,4.41176470588,3285.7142	union all
select	42,858018,54.6296296296,16477.9411	union all
select	44,909460,29.6296296296,2000.0	union all
select	45,910858,57.4074074074,4900.0	union all
select	46,914224,51.8518518519,6173.4375	union all
select	47,928639,54.6296296296,4520.0	union all
select	48,935950,26.8518518519,7000.0	union all
select	49,938798,69.1176470588,7392.8571	union all
select	50,942063,51.8518518519,13537.8571	union all
select	51,942870,82.4074074074,9916.6666	union all
select	52,957891,51.8518518519,14337.0689	union all
select	55,990663,54.6296296296,12444.4444	union all
select	56,1001691,51.8518518519,7843.75	union all
select	57,1023726,30.5555555556,3500.0	union all
select	58,1044252,49.0740740741,2500.0	union all
select	61,1078021,17.6470588235,6857.1428	union all
select	63,1102247,49.0740740741,7088.8653	union all
select	64,1108638,46.2962962963,3611.1111	union all
select	65,1112386,30.5555555556,6545.4545	union all
select	66,1120121,43.5185185185,10000.0	union all
select	68,1122500,49.0740740741,2750.0	union all
select	71,1162437,51.8518518519,13807.6923	union all
select	73,1193092,33.8235294118,1500.0	union all
select	74,1203232,43.5185185185,2250.0	union all
select	75,1206217,40.7407407407,5833.3333	union all
select	78,1216685,12.962962963,10000.0	union all
select	81,1221820,46.2962962963,7000.0	union all
select	85,1223473,43.5185185185,12318.1818	union all
select	88,1223584,51.8518518519,4533.3333	union all
select	99,1223909,51.8518518519,11884.6153	union all
select	101,1223921,46.2962962963,8776.923	union all
select	108,1224028,51.8518518519,8000.0	union all
select	109,1224042,71.2962962963,6350.0	union all
select	112,1224086,16.6666666667,1250.0	union all
select	113,1224098,25.9259259259,3687.5	union all
select	120,1224148,51.8518518519,7000.0	union all
select	123,1224177,73.5294117647,7857.1428	union all
select	124,1224194,74.0740740741,20208.3333	union all
select	125,1224209,26.8518518519,4052.6315

) as x (id, UserId, FinBurdern, AvgMLoan)
*/
-- определение шага тарифа по ср. телу МЗ или фин нагрузке
select
    ucl.UserId
    ,rate_ed_FinBurden as FinBurdern
    ,cu.num_ed_ClosedMLAmt as AvgMloan
into ##user
from dbo.UserCustomLists ucl
outer apply
(
    select top 1
        cu.rate_ed_FinBurden
        ,cu.num_ed_ClosedMLAmt
    from dbo.checkUnblocked cu 
    where cu.UserID = ucl.UserId
    order by column1 desc
) cu
where CustomlistID = 55


select *
from dbo.checkUnblocked
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
/*
select *
from dbo.CustomList

select * from dbo.UserCustomLists l where l.CustomListId = 47 -- Mango
insert dbo.UserCustomLists (CustomListId, UserId, DateCreated)
select 53, f.UserId, h.DateCreated  -- select *
from #finalds f 
inner join dbo.UserTariffHistory h on h.UserId = f.UserId and h.islatest = 1
inner join dbo.vw_TariffSteps t on t.StepID = h.StepID
    and t.TariffId = 2

select *
from dbo.UserStatusHistory h
where h.islatest = 1
    and h.userid in (872844,873528,878107)
update statistics dbo.Credits with fullscan

*/