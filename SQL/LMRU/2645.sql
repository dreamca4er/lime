-- 1. Берем должников, переданных в июне
-- 2. Берем их просрочки за определенный период
-- 3. Берем должников из п1 только тогда, когда они 4ый день в просрочке на дату передачи их коллекторам
-- 4. Берем платежи (1.07 - 29.07) по должникам по след. принципу: 
--1 июля: платежи в эту дату по суммам, поступившим в обработку коллекторов Г1 в интервале со 2.06 по 30.06
--2 июля: платежи в эту дату по суммам, поступившим в обработку коллекторов Г1 в интервале со 3.06 по 30.06
--...
--29 июля: платежи в эту дату по суммам, поступившим в обработку коллекторов Г1 30.06

with dch as 
(
    select
        cast(dch.DateCreated as date) as collectorDate
       ,dch.DebtorId
       ,d.CreditId
       ,c.UserId
    from dbo.DebtorCollectorHistory dch
    inner join dbo.Debtors d on d.Id = dch.DebtorId
    inner join dbo.Credits c on c.Id = d.CreditId
    where dch.CollectorId in
        (
            select
              u.UserId
            from CmsContent_LimeZaim.dbo.Users u
            join CmsContent_LimeZaim.dbo.UserGroupLinks ugl on ugl.UserId = u.UserId
            where ugl.UserGroupId = 44
        )
        and dch.DateCreated >= '20170601'
        and dch.DateCreated < '20170701'
)

,cs as 
(
    select
        csh.CreditId
       ,cast(csh.DateStarted as date) as overdueStarted
       ,cast(csh_next.DateStarted as date) as overdueFinished
    from CreditStatusHistory csh
    left join CreditStatusHistory csh_next on csh_next.CreditId = csh.CreditId
        and csh_next.id > csh.id
        and csh_next.Id = (select min(csh_next1.id)
                           from CreditStatusHistory csh_next1
                           where csh_next1.CreditId = csh_next.CreditId
                               and csh_next1.status != 3
                               and csh_next1.id > csh.id)
    where csh.CreditId in (select creditId from dch)
        and csh.Status = 3
        and cast(csh.DateStarted as date) > dateadd(d, -4, '20170601')
        and cast(csh.DateStarted as date) <= dateadd(d, -4, '20170701')
)

,neededDCH  as 
(
    select 
        dch.*
       ,cs.overdueStarted
    from dch
    inner join cs on cs.CreditId = dch.CreditId
        and datediff(d, cs.overdueStarted, dch.collectorDate) + 1 = 4
        and (cs.overdueFinished >= dch.collectorDate or cs.overdueFinished is null)
)

,cp as 
(
    select
        cp.CreditId 
       ,cast(cp.DateCreated as date) as paymentDate
       ,cp.Amount as N'Тело'
       ,cp.PercentAmount as N'Проценты'
       ,cp.CommissionAmount as N'Комиссия'
       ,cp.PenaltyAmount as N'Штрафы'
       ,cp.LongPrice as N'Продления'
       ,cp.TransactionCosts as N'Транз. издержки'
    from dbo.CreditPayments cp
    where cp.CreditId in (select dch.CreditId from dch)
        and cp.DateCreated >= '20170701'
        and cp.DateCreated < '20170730'
)

select
    dch.UserId as N'Клиент'
   ,cp.*
   ,dch.collectorDate
   ,dch.overdueStarted
from cp
inner join neededDCH dch on dch.CreditId = cp.CreditId
    and dch.collectorDate >= dateadd(d, -29, cast(cp.paymentDate as date))
    and dch.collectorDate <= '20170630'

