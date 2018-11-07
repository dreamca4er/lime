select
    mw.Description as "Канал выдачи"
    ,s.Score
    ,c.UserId as "Id клиента"
    ,c.Id as "Id кредита"
    ,c.Amount as "Сумма кредита"
    ,cs.Description as "Статус кредита"
    ,c.DateStarted as "Дата выдачи"
    ,c.DatePaid as "Дата погашения фактическая"
    ,dateadd(d, c.Period, c.DateStarted) as "Дата погашения по договору"
    ,cp.AmountPaid as "Оплачено тела"
    ,cp.PercentPaid as "Оплачено процентов"
    ,cp.OtherPaid as "Оплачено прочего"
from dbo.Credits c
inner join dbo.EnumDescriptions mw on mw.Value = c.Way
    and mw.Name = 'MoneyWay'
inner join dbo.EnumDescriptions cs on cs.Value = c.Status
    and cs.Name = 'CreditStatus'
outer apply
(
    select top 1
        mlr.Score
    from dbo.MlScoringResponses mlr
    inner join dbo.CreditRobotResults crr on crr.id = mlr.CreditRobotResultId
    where crr.Created < c.DateCreated
        and crr.UserId = c.UserId
    order by mlr.id desc
) s
outer apply
(
    select
        count(*) as PaymentsCount
        ,count(case when p.Way = 6 then 1 end) as VirtPaymentsCount
        ,sum(cp.Amount) as AmountPaid
        ,sum(cp.PercentAmount) as PercentPaid
        ,sum(cp.CommissionAmount + cp.PenaltyAmount + cp.LongPrice + cp.TransactionCosts) as OtherPaid
    from dbo.CreditPayments cp
    inner join dbo.Payments p on p.id = cp.PaymentId
    where cp.CreditId = c.id
) cp
where c.DateStarted >= '20180101'
    and c.Status not in (5, 8)
    and not (cp.PaymentsCount = cp.VirtPaymentsCount and c.Status = 2)
    
