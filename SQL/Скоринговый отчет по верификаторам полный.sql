set transaction isolation level read uncommitted;
/*
DECLARE @StartDate DATE, @EndDate DATE
SET @StartDate = '2017-06-01'
SET @EndDate = '2017-06-30'
DECLARE @CreditNumberFrom INT = null
DECLARE @CreditNumberTo INT = null
declare @Tariff int = 1
*/
declare @EndM1 date = dateadd(day, -1, dateadd(month, 1,  dateadd(day, 1, @EndDate)))
declare @Endm2 date = dateadd(day, -1, dateadd(month, 2,  dateadd(day, 1, @EndDate)))
declare @EndM3 date = dateadd(day, -1, dateadd(month, 3,  dateadd(day, 1, @EndDate)))
declare @PercentEdge int = 6
declare @BonusFund int = 50000
--Вычисляем среднее время реагирования админа на заявку в минутах. Заявки учитывать только по первичным клиентам в заданный отчётный период.
--Вычисляется как разница между временем попадания клиента в статус "Нужен кредит" и временем попадания в статус клиента "Есть тариф и нет кредитов".
--при этом статус клиента "Есть тариф и нет кредитов" (11) должен следовать за стаусом "Нужен кредит" (9)
;with s as
(
    select
        sh.CreatedByUserId
        ,sh.DateCreated
        ,sh.[Status]
        ,sh.UserId
        ,row_number() over (partition by sh.UserId order by sh.id) as RowNum
    from UserStatusHistory AS sh
    where cast(sh.DateCreated as date) between @StartDate and @EndDate
    and sh.UserId in (select UserId from Credits where [Status] not in (5, 8))  
    and sh.UserId <> sh.CreatedByUserId and sh.CreatedByUserId > 10
) 
select
    --s1.UserId
    --,s1.[Status]  AS s1_Status
    --,s1.DateCreated AS s1_Date 
    --,s2.[Status] AS s2_Status
    s2.CreatedByUserId  AS AdminId
    --средняя разница в минутах между статусом клиента 9 и 11 и 9 и 10
    ,avg(cast(datediff(minute, s1.DateCreated, s2.DateCreated) as float)) as AvgReactionTime
into #ReactionTime
from s as s1
inner join s as s2 on s1.UserId = s2.UserId and s2.RowNum = s1.RowNum + 1
where s2.[Status] = 11 and s1.[Status] in (9,10)
group by s2.CreatedByUserId
--Админы присвоивышие тариф клиентам
;with s as
(
    select
        sh.CreatedByUserId
        ,sh.DateCreated
        ,sh.[Status]
        ,sh.UserId
        ,row_number() over (partition by sh.UserId order by sh.id) as RowNum
    from Credits as c
    inner join UserStatusHistory as sh on sh.UserID = c.UserId
    where
    cast(dateadd(day, c.Period, c.DateStarted) as date) between @StartDate and @EndDate
    and cast(right(c.DogovorNumber, 3) as int) between isnull(@CreditNumberFrom, 1) and isnull(@CreditNumberTo, (select count(*) from Credits where UserId = c.UserId and [Status] not in (5, 8) ) )
    and c.[Status] not in (5, 8)
) 
select
    s2.CreatedByUserId as AdminId
into #AdminTariffs
from s s1 
inner join s as s2 on s1.UserId = s2.UserId and s2.RowNum = s1.RowNum + 1
where
s1.[Status] in (9,10) and s2.[Status] = 11
and s2.UserId <> s2.CreatedByUserId 
and s2.CreatedByUserId > 10
group by s2.CreatedByUserId 
    
;with Pay as 
(
    select
        c.Id as CreditID
        ,sum ( case when p.DateCreated < @EndDate then cp.Amount end ) as amt_M0
        ,sum ( case when p.DateCreated < @EndM1 then cp.Amount end ) as amt_M1
        ,sum ( case when p.DateCreated < @EndM2 then cp.Amount end ) as amt_M2
        ,sum ( case when p.DateCreated < @EndM3 then cp.Amount end ) as amt_M3
        ,sum ( case when p.DateCreated < @EndDate then cp.Amount + cp.PercentAmount + cp.CommissionAmount + cp.LongPrice + cp.TransactionCosts + cp.PenaltyAmount end ) as all_M0
        ,sum ( case when p.DateCreated < @EndM1 then cp.Amount + cp.PercentAmount + cp.CommissionAmount + cp.LongPrice + cp.TransactionCosts + cp.PenaltyAmount end ) as all_M1
        ,sum ( case when p.DateCreated < @EndM2 then cp.Amount + cp.PercentAmount + cp.CommissionAmount + cp.LongPrice + cp.TransactionCosts + cp.PenaltyAmount end ) as all_M2
        ,sum ( case when p.DateCreated < @EndM3 then cp.Amount + cp.PercentAmount + cp.CommissionAmount + cp.LongPrice + cp.TransactionCosts + cp.PenaltyAmount end ) as all_M3
    from Credits as c
    inner join CreditPayments as cp on cp.CreditId = c.Id
    inner join Payments as p on p.Id = cp.PaymentId
    where p.Way <> 6
    group by c.Id
) 
,Overdue as 
(
    select
        c.Id as CreditId
        ,avg(cast (datediff(day, case when cshs.DateStarted > @EndM1 then null else cshs.DateStarted end, (case when cshe.DateStarted is null or cshe.DateStarted > @EndM1 then @EndM1 else cshe.DateCreated end)) as numeric))  as M1
        ,avg(cast (datediff(day, case when cshs.DateStarted > @EndM2 then null else cshs.DateStarted end, (case when cshe.DateStarted is null or cshe.DateStarted > @EndM2 then @EndM2 else cshe.DateCreated end)) as numeric)) as M2
        ,avg(cast (datediff(day, case when cshs.DateStarted > @EndM3 then null else cshs.DateStarted end, (case when cshe.DateStarted is null or cshe.DateStarted > @EndM3 then @EndM3 else cshe.DateCreated end)) as numeric))  as M3
    from
    Credits as c
    --cshs - начало просрочки кредита
    left join CreditStatusHistory as cshs on cshs.CreditId = c.Id 
    --cshe - конец просрочки кредита
    left join CreditStatusHistory as cshe on cshe.id = (select min(id)
                                                        from CreditStatusHistory
                                                        where DateStarted > cshs.DateStarted
                                                        and CreditId = cshs.CreditId)
                                                        
    where cshs.[Status] = 3
    group by c.Id
)
,ApprovedApplications as
(
    select
        CreatedByUserId as AdminId
        ,count(Id) as CountApprovedApplications
    from UserTariffHistory 
    where UserId <> CreatedByUserId
    and cast(isnull(DateLastUpdated,DateCreated) as date) between  @StartDate and @EndDate
    group by CreatedByUserId
)
,BlockedApplications as
(
    select
        CreatedByUserId as AdminId
        ,count(id) as CountBlockedApplications
    from UserBlocksHistory
    where
    UserId <> CreatedByUserId
    and cast(isnull(DateLastUpdated,DateCreated) as date) between  @StartDate and @EndDate
    group by CreatedByUserId
)
,Verificator as
(
    select
        c.Id as CreditId
        ,max( case when h.CreatedByUserId <> h.UserID and h.CreatedByUserId > 10  then h.ID end) as AdminID
        ,max( h.ID ) as TotalID
    from Credits as c
    left join UserTariffHistory as h on h.UserId = c.UserId and h.DateCreated < c.DateCreated
    where cast(dateadd(day, c.Period, c.DateStarted) as date) between @StartDate and @EndDate 
    and h.CreatedByUserId in (select AdminId from #AdminTariffs)
    group by c.Id 
)
select
    adm.UserId as VerId 
    , adm.UserName as VerSurname 
    , sum(c.Amount) as TotalAmount
    
    , 100 * sum(c.Amount - isnull(p.amt_M1, 0) )  / sum(c.Amount)  as NPL_1M
    , 100 * sum(c.Amount - isnull(p.amt_M2, 0) )  / sum(c.Amount)  as NPL_2M
    , 100 * sum(c.Amount - isnull(p.amt_M3, 0) )  / sum(c.Amount)  as NPL_3M
    , 100 * ( sum(p.amt_M0) / sum(c.Amount) ) as RecRate_0M
    , 100 * ( sum(p.amt_M1) / sum(c.Amount) ) as RecRate_1M
    , 100 * ( sum(p.amt_M2) / sum(c.Amount) ) as RecRate_2M
    , 100 * ( sum(p.amt_M3) / sum(c.Amount) ) as RecRate_3M
    
    , 100 * ( sum(p.all_M0) / sum(c.Amount) ) as Profit_0M
    , 100 * ( sum(p.all_M1) / sum(c.Amount) ) as Profit_1M
    , 100 * ( sum(p.all_M2) / sum(c.Amount) ) as Profit_2M
    , 100 * ( sum(p.all_M3) / sum(c.Amount) ) as Profit_3M
    , avg(ovr.M1) as AvgOverdue_1M 
    , avg(ovr.M2) as AvgOverdue_2M 
    , avg(ovr.M3) as AvgOverdue_3M 
    , max(100 * ( cast(apr.CountApprovedApplications as numeric) 
    / (apr.CountApprovedApplications + blk.CountBlockedApplications) )) as Conversion
    , max(rt.AvgReactionTime) as avgTime 
    
from Credits as c
left join Verificator as v on v.CreditId = c.Id
left join UserTariffHistory h on h.Id = isnull(v.AdminID, v.TotalID)
left join CmsContent_LimeZaim.dbo.Users adm on adm.UserId = h.CreatedByUserId
left join Pay as p on p.CreditID = c.ID
left join Overdue as ovr on ovr.CreditId = c.Id
left join ApprovedApplications as apr on apr.AdminId = adm.UserId
left join BlockedApplications as blk on blk.AdminId = adm.UserId
left join #ReactionTime as rt on rt.AdminId = adm.UserId
left join dbo.Tariffs as t on t.ID = c.TariffID
where 
cast(dateadd(day, c.Period, c.DateStarted) as date) between @StartDate and @EndDate  --дата выплаты по договору (без учета продлений) попадает в отчетный период
and cast(right(c.DogovorNumber, 3) as int) between isnull(@CreditNumberFrom, 1) and isnull(@CreditNumberTo, (select count(*) from Credits where UserId = c.UserId and [Status] not in (5, 8) ) )
and t.[Type] in (@Tariff)
group by adm.UserId, adm.UserName 
drop table #ReactionTime
drop table #AdminTariffs