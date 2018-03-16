select
    u.username as "Сотрудник"
    ,ca.UserId as "id клиента"
    ,ca.CreditId as "id кредита"
    ,ca.CollectorAssignStart as "Дата прикрепления"
    ,datediff(d, ca.OverdueStart, ca.CollectorAssignStart) + 1 as "Дней просрочки на дату прикрепления"
    ,ca.CollectorAssignEnd as "Дата открепления"
    ,datediff(d, ca.OverdueStart, isnull(ca.CollectorAssignEnd, getdate())) + 1 as "Дней просрочки на дату открепления (или на текущую дату, если кредит прикреплен)"
    ,ca.Amount as "Платежи по телу долга"
    ,ca.PercentAmount + ca.CommissionAmount + ca.PenaltyAmount as "Платежи по комиссиям, процентам и штрафам"
    ,ca.LongPrice as "Плата за продление"
    ,ca.TransactionCosts as "Транз. издержки"
    ,ld.LastPaymentDate as "Дата последнего платежа за период работы коллектора с должником"
    ,case 
        when c.TariffId = 4
        then N'ДЗ'
        else N'КЗ'
    end as "Тип займа"
    ,cs.Description as "Статус займа"
from dbo.tf_getCollectorAssigns('20180201', '20180228', 0) ca
inner join dbo.Credits c on c.id = ca.CreditId
inner join dbo.EnumDescriptions cs on cs.Value = c.Status
    and cs.Name = 'CreditStatus'
inner join syn_CmsUsers u on u.userid = ca.CollectorId
outer apply
(
    select max(DateCreated) as LastPaymentDate
    from dbo.CreditPayments cp
    where cp.CreditId = c.id
        and cp.DateCreated between ca.CollectorAssignStart and ca.CollectorAssignEnd
) as ld
