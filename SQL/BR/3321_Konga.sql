select
    fu.id
    ,fu.Lastname
    ,fu.Firstname
    ,fu.Fathername
    ,fu.mobilephone
    ,fu.emailaddress
    ,cr.Score
    ,c.STCreditsCount
    ,c.LTCreditsCount
    ,st.StepName as STTariff
    ,lt.StepName as LTTariff
    ,(select min(dt) from (values (c.LTDatePaid), (c.STDatePaid)) d(dt)) as LastPaidCreditDate
    ,case 
        when c.STDatePaid > c.LTDatePaid or c.LTDatePaid is null and c.STDatePaid is not null
        then N'КЗ'
        when c.LTDatePaid > c.STDatePaid or c.STDatePaid is null and c.LTDatePaid is not null
        then N'ДЗ'
    end as LastPaidCreditType
    ,datediff(d, er.DateCreated, getdate()) as CHDays
from dbo.FrontendUsers fu
inner join dbo.UserStatusHistory ush on ush.UserId = fu.id
    and ush.IsLatest = 1
outer apply
(
    select
        uth.StepId
        ,ts.StepOrder
        ,ts.StepName
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    where ts.TariffID = 2
        and uth.IsLatest = 1
        and uth.UserId = fu.id
) st
outer apply
(
    select
        uth.StepId
        ,ts.StepOrder
        ,ts.StepName
    from dbo.UserTariffHistory uth
    inner join dbo.vw_TariffSteps ts on ts.StepID = uth.StepId
    where ts.TariffID = 4
        and uth.IsLatest = 1
        and uth.UserId = fu.id
) lt
outer apply 
(
    select top 1 cr2.Created, mr.Score
    from dbo.CreditRobotResults cr2
    inner join dbo.MlScoringResponses mr on mr.CreditRobotResultId = cr2.Id
    where cr2.UserId = fu.Id
    order by cr2.Created desc
) cr
outer apply
(
    select 
        count(case when c.TariffId != 4 then 1 end) as STCreditsCount
        ,count(case when c.TariffId = 4 then 1 end) as LTCreditsCount
        ,max(case when c.TariffId != 4 then c.DatePaid end) as STDatePaid
        ,max(case when c.TariffId = 4 then c.DatePaid end) as LTDatePaid
    from dbo.Credits c
    where c.userid = fu.id
        and c.status = 2
) c
outer apply
(
    select 
        max(er.DateCreated) as DateCreated
    from dbo.EquifaxRequests er
    where er.UserId = fu.id
) er
where (st.StepId is not null or lt.StepId is not null)
    and not exists 
        (
            select 1 from dbo.Credits c
            where c.userid = fu.Id
                and c.Status in (1, 3)
        )
    and ush.Status not in (6, 12)