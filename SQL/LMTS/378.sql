declare
    @dateFrom date = '20170802'
    ,@dateTo date = '20170901'
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
        c.id as creditid
        ,c.UserId
        ,dch.DateCreated
    from dbo.DebtorCollectorHistory dch
    inner join dbo.Debtors d on d.id = dch.DebtorId
    inner join dbo.Credits c on c.id = d.CreditId
    where cast(dch.DateCreated as date) = @dateFrom
        and dch.CollectorId = @collector
                                
)

,lcu as 
(
    select *
    from dbo.LongCreditUnits lcu
    where lcu.CreditId in (select creditid from creditsCte)
        and lcu.DateCreated >= @dateFrom
        and lcu.DateCreated < @dateTo
)

select
    cc.userid as "Клиент"
    ,cp.DateCreated as "Дата платежа"
    ,cp.Amount as "Платеж по телу кредита"
    ,cp.PercentAmount 
        + cp.CommissionAmount 
        + cp.PenaltyAmount 
        + cp.PenaltyAmount 
        + cp.LongPrice 
        + cp.TransactionCosts as "Прочий платеж"
from creditsCte cc
inner join dbo.CreditPayments cp on cp.CreditId = cc.creditid
    and cp.DateCreated >= @dateFrom
    and cp.DateCreated < @dateTo
    and not exists (
                    select 1 from dbo.Payments p
                    where p.Id = cp.PaymentId
                        and p.Way = 6
                   )
outer apply
(
    select top 1
        lcu.datecreated as dt
    from lcu
    where lcu.creditid = cc.creditid
    order by lcu.DateCreated desc
) as prolong
where prolong.dt is null
    or cp.DateCreated < prolong.dt