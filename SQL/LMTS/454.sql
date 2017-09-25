declare
    @assignFrom date = '20170904'
    ,@assignTo date = '20170915'
    ,@payFrom date = '20170901'
    ,@payTo date = '20170915'
--    @assignFrom date = '20170802'
--    ,@assignTo date = '20170901'
--    ,@payFrom date = '20170801'
--    ,@payTo date = '20170901'
    ,@collector int = case 
                        when exists (
                                        select 1 from dbo.Tariffs t
                                        where t.id = 2
                                            and t.Name = 'Lime'
                                      )
                        then 1174
                        when exists (
                                        select 1 from dbo.Tariffs t
                                        where t.id = 2
                                            and t.Name = 'Konga'
                                      )
                        then 2230
                      end
;

with creditsCte as 
(
    select distinct 
        creditid
        ,UserId
        ,collectorAssignStart
        ,collectorAssignEnd
    from tf_getCollectorAssigns(@assignFrom, @assignTo, @collector)
--    where userid = 1053873 
)

select
    cc.userid as "Клиент"
    ,cp.DateCreated as "Дата платежа"
    ,cp.Amount as "Платеж по телу кредита"
    ,cp.PercentAmount 
        + cp.CommissionAmount 
        + cp.PenaltyAmount 
        + cp.LongPrice 
        + cp.TransactionCosts as "Прочий платеж"
--    ,ca.assignid
--    ,cc.creditid
--    ,ca.collectorid
from creditsCte cc
inner join dbo.CreditPayments cp on cp.CreditId = cc.creditid
    and cast(cp.DateCreated as date) >= @payFrom
    and cast(cp.DateCreated as date) <= @payTo
    and not exists (
                    select 1 from dbo.Payments p
                    where p.Id = cp.PaymentId
                        and p.Way = 6
                   )
    and cp.datecreated < collectorAssignEnd
left join tf_getCollectorAssigns(@payFrom, @payTo, 0) ca on ca.userid = cc.userid
    and cp.DateCreated >= ca.collectorAssignStart
    and (cp.DateCreated <= ca.collectorAssignEnd or ca.collectorAssignEnd is null)
    and (ca.collectorid is null 
            or @collector = 2230 and ca.collectorid in (@collector, 2198, 2358)
            or @collector = 1174 and ca.collectorid in (@collector, 1375)
        )