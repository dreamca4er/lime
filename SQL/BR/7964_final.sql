drop table if exists #qwe
;
drop table if exists #data
;

select po.ProductId, DateOperation, po.State -- select count(*)
into #qwe
from acc.ProductOperation po
where po.ProductType in (1,2)
    and po.DateOperation between '20190301' and '20190506'
    and po.OperationTemplateId in (5,15) 

select q.ProductId, q.DateOperation
INTO #data
from #qwe q
where exists (
    select 1 from #qwe q1
    where q1.ProductId = q.ProductId
        and q1.DateOperation < q.DateOperation
        and q1.State = 2
    )
    and exists (
    select 1 from #qwe q1
    where q1.ProductId = q.ProductId
        and q1.DateOperation > q.DateOperation
        and q1.State = 2
    )
    and q.State != 2
    and not exists (
    select 1 from #qwe q1
    where q1.ProductId = q.ProductId
        and q1.DateOperation = q.DateOperation
        and q1.State = 2
    )
 GROUP BY q.ProductId, q.DateOperation

/
--select count(*) from #data

drop table if exists #temp
;

select top 100
    d.ProductId
    , min(DateOperation) as DateOperation
into #temp
from #data d
inner join prd.vw_product p on p.Productid = d.ProductId
    and p.Status = 4
where not exists
    (
        select 1 from dbo.br7964Done done
        where done.ProductId = d.ProductId
    )
group by d.ProductId
order by d.ProductId
;
/
declare
    @RecalcFrom datetime = '2019-03-11 00:00:01'
;


select 
    @RecalcFrom as recalcDate
    , getdate() as operationDate
    ,
    json_query(replace(replace((
        select ProductId
        from #temp
        for json auto
    ), '{"ProductId":', ''), '}', '')) as productIds
    , newid() as messageId
    , getdate() as  createdOn
    ,
    json_query((
        select 
            'TestAPI' as serviceUuid
            , newid() as transactionUuid
            , newid() as correlationUuid
            , cast(0x44 as uniqueidentifier) as userUuid
            , json_query('[]') as conversation
        from (select 1 as c) d
        for json auto, without_array_wrapper
    )) as context
from (select 1 as a) b
for json auto, without_array_wrapper
;

/
drop table if exists #p
;

select p.id as ProductId
into #p
from prd.Product p
where id in (select ProductId from #temp)
;

with qwe as 
(
    select po.ProductId, DateOperation, po.State -- select count(*)
    from acc.ProductOperation po
    inner join #p p on p.ProductId = po.ProductId
    where po.ProductType in (1,2)
        and po.DateOperation between '20190301' and '20190506'
        and po.OperationTemplateId in (5,15) 
)

select q.ProductId, p.StartedOn, q.DateOperation
from qwe q
inner join prd.Product p on p.id = q.ProductId
where exists (
    select 1 from qwe q1
    where q1.ProductId = q.ProductId
        and q1.DateOperation < q.DateOperation
        and q1.State = 2
    )
    and exists (
    select 1 from qwe q1
    where q1.ProductId = q.ProductId
        and q1.DateOperation > q.DateOperation
        and q1.State = 2
    )
    and q.State != 2
    and not exists (
    select 1 from qwe q1
    where q1.ProductId = q.ProductId
        and q1.DateOperation = q.DateOperation
        and q1.State = 2
    )
 GROUP BY q.ProductId, p.StartedOn, q.DateOperation
 
;


select CalcStatus
from prd.Product
where id in ( select ProductId from #p p)
group by CalcStatus

select *
from prd.OperationLog
where Suspended = 1
    and ProductId in ( select ProductId from #p p)
    
select *
from bi.vw_bus
where Command = 'Prd.Contract.Messaging.Commands.RecalculateByIdCommand, Prd.Contract.Messaging'
/*
select * -- delete
from prd.OperationLog
where ProductId in (695211)
    and Suspended = 1
    and CommandType like 'Prd.Domain.Commands.RepaymentCommand%'
    
select * -- update ol set Suspended = 0
from prd.OperationLog ol 
where ProductId in (695211)
    and Suspended = 1
    
    
*/
/

-- Список кредитов, обнаруженных первоначально
select p.StatusName, count(*) as cnt
from dbo.br7964 b
inner join prd.vw_product p on p.Productid = b.ProductId
group by StatusName
;

-- Ищем кредиты с пропущенным днем = еще не пересчитанные
drop table if exists #qwe
;
drop table if exists #data
;

select po.ProductId, DateOperation, po.State -- select count(*)
into #qwe
from acc.ProductOperation po
inner join dbo.br7964 b on b.ProductId = po.ProductId 
where po.ProductType in (1,2)
    and po.DateOperation between '20190301' and '20190506'
    and po.OperationTemplateId in (5,15) 

select q.ProductId, q.DateOperation
INTO #data
from #qwe q
where exists (
    select 1 from #qwe q1
    where q1.ProductId = q.ProductId
        and q1.DateOperation < q.DateOperation
        and q1.State = 2
    )
    and exists (
    select 1 from #qwe q1
    where q1.ProductId = q.ProductId
        and q1.DateOperation > q.DateOperation
        and q1.State = 2
    )
    and q.State != 2
    and not exists (
    select 1 from #qwe q1
    where q1.ProductId = q.ProductId
        and q1.DateOperation = q.DateOperation
        and q1.State = 2
    )
 GROUP BY q.ProductId, q.DateOperation
;

-- смотрим кто в каком статусе из непересчитанных
select
    p.StatusName
    , count(*) as cnt
from #data d
inner join prd.vw_product p on p.Productid = d.ProductId 
group by p.StatusName 

select count(*)
-- update c set DebtorProhibitInteractionType = 0, ModifiedBy = 0x44, ModifiedOn = getdate()
from dbo.br7964 b
inner join prd.Product p on p.id = b.ProductId
inner join client.Client c on c.id = p.ClientId
where DebtorProhibitInteractionType = 8
/

-- Список кредитов, обнаруженных первоначально
select
    c.clientid
    , c.LastName
    , c.FirstName
    , c.FatherName
    , c.PhoneNumber
    , iif(c.EmailConfirmed = 1, c.Email, null) as Email
    , isnull(p2.ContractNumber, p.ContractNumber) as ContractNumber
    , iif(p2.ContractNumber is not null, 1, 0) as HasNextCredit
from dbo.br7964 b
inner join prd.vw_product p on p.Productid = b.ProductId
inner join client.vw_Client c on c.ClientId = p.ClientId
outer apply
(
    select top 1 p2.ContractNumber , p2.StatusName
    from prd.vw_product p2
    where p2.ClientId = p.ClientId
        and p2.Status > 2
        and p2.ContractNumber > p.ContractNumber
        and p2.Status != 5
    order by p2.ContractNumber desc 
) p2
where p.Status != 5
    and isnull(p2.ContractNumber, p.ContractNumber) is not null
/


-- для продукта 723262 удаляем досрочное погашение от 10.04 и делаем перерасчет с 10.04.2019 00:01:00
select * --delete 
from Prd.OperationLog 
where Id = 52528708 

-- для продукта 729918 переносим досрочное погашение на 06.04 и делаем перерасчет с 05.04.2019 09:00:00
select * -- update ol set OperationDate = '20190406 09:51:41.379'  
from Prd.OperationLog ol
where Id in (51790086, 51790481, 51792050)
update ol set Suspended = 0 from Prd.OperationLog ol where Id in (51790086, 51790481, 51792050)


-- для продукта 733134 переносим досрочное погашение на 21.03 и делаем перерасчет с 20.03.2019 17:00:00
update Prd.OperationLog set OperationDate = '20190321 17:46:00.012' where Id = 50273093 
update Prd.OperationLog set Suspended = 0 where Id in (50273093, 50273103)


-- для продукта 723548 переносим досрочное погашение на 09.04 и делаем перерасчет с 08.04.2019 09:00:00
update Prd.OperationLog set OperationDate = '20190409 09:17:49.506' where Id = 52166816 
update Prd.OperationLog set Suspended = 0 where Id in (52166816, 52166870)

-- для продукта 706744 удаляем досрочное погашение от 29.03 и делаем перерасчет с 29.03.2019 00:01:00
delete from Prd.OperationLog where Id = 51118582 

select *
from Prd.OperationLog ol
where productid = 723548 

select p.ClientId
from prd.vw_Product p
inner join prd.Product p2 on p2.ClientId = p.ClientId
inner join dbo.br7964 b on b.ProductId = p2.id
where Status in (2, 3, 4, 6, 7)
group by p.ClientId
having count(*) > 1


grant update on mkt.ProductReductionFactor to pinsupport
/
drop table if exists #c
;

select b.*, cbp.*, os.OverdueStart--, cbn.*
into #c
from prd.vw_product p2
inner join dbo.br7964 b on b.ProductId = p2.productid
outer apply
(
    select top 1
        cb.DateOperation
        , (cb.ActiveAmount + cb.RestructAmount) * -1 as ActiveAmount
        , (cb.ActivePercent + cb.RestructPercent) * -1  as ActivePercent
        , (cb.OverdueAmount + cb.OverdueRestructAmount) * -1 as OverdueAmount
        , (cb.OverduePercent + cb.OverdueRestructPercent) * -1 as OverduePercent
        , cb.Fine * -1 as Fine
        , cb.Commission * -1 as Commission
    from dbo.br7964CreditBalance cb
    where cb.ProductId = b.ProductId
        and cb.InfoType = 'debt'
    order by cb.DateOperation desc 
) cbp
outer apply
(
    select max(sl.StartedOn) as OverdueStart
    from prd.vw_statusLog sl
    where sl.ProductId = p2.Productid
) os
where p2.Status = 4
    and cbp.OverdueAmount = 0
    and cbp.OverduePercent = 0
    and cbp.Fine = 0
    and cbp.ActiveAmount > 0
--    and os.OverdueStart > b.Date

;

-- 693088 699389 716497 735011 731561 730924 739452 742992 690652 692152 692995 697480 700873 716243 720916 739574 Fixed 
-- 693299,693425,693910,694589,696387 696506,697296,697310,698264,698574 698577,698761,699281,699737,699800
-- 699982,700433,700917,701682,703126,703718,703748 704592,704652,709448,709785,709993,710614,710635,710687,711886,713658,713923
-- 673752,714422,714690,715307,717614,717685,718102,718584,718619,718872,719263,719531,720379,720774,721030,721185
-- 722700,723139,723905,727186,728656,728820,730178,730348,730643,730805,731035,731460,732701,736639,736767,736887
-- 738196,739137,739166,739666,739669,739685,740792,742016,742494,742647,742775,743077,746485,747326,747354,749434
-- 709649
-- 713853
-- 716337
-- 728457,730014,730719,713066,732031,714279
-- 689130
-- 689227
-- 705365,707663,725483,725683,725718,725840,744032,744661,746240,746378
-- 746483,663203,686343,686465,688432,688646,687826,725453
-- 694796 Wont do
-- 686372 Не опдатил тонну комиссии
-- 666545 вкинул денег, осталась только  комиссия, погасится
-- 704239, 663887,746807 все равно просрочен, придурок
;

select 
    c.ProductId
    , cbn.*
from #c c
outer apply
(
    select top 1 
        (cb.ActiveAmount + cb.RestructAmount) * -1 as ActiveAmount
        , (cb.ActivePercent + cb.RestructPercent) * -1  as ActivePercent
        , (cb.OverdueAmount + cb.OverdueRestructAmount) * -1 as OverdueAmount
        , (cb.OverduePercent + cb.OverdueRestructPercent) * -1 as OverduePercent
        , cb.Fine * -1 as Fine
        , cb.Commission * -1 as Commission
    from bi.CreditBalance cb
    where cb.ProductId = c.Productid
        and cb.InfoType = 'debt'
    order by cb.DateOperation desc
) cbn
outer apply
(
    select top 1 lts.ScheduleSnapshot
    from prd.LongTermSchedule lts
    inner join prd.LongTermScheduleLog ltsl on ltsl.ScheduleId = lts.Id
    where lts.ProductId = c.Productid
    order by ltsl.StartedOn desc
) ss
outer apply
(
    select 
        sum(Amount) as AmountLeft
        , min(case when Date >= '20190412' then Date end) as NextDate 
    from openjson(ss.ScheduleSnapshot) with
    (
        Date date '$.Date'
        , Amount numeric(18, 2) '$.Amount'
        , "Percent" numeric(18, 2) '$.Percent'
        , Residue numeric(18, 2) '$.Residue'
    ) js
    where Date >= '20190412'
) s
where 1=1
--    and not exists
--    (
--        select 1 
--        from openjson(ss.ScheduleSnapshot) with
--        (
--            Date date '$.Date'
--            , Amount numeric(18, 2) '$.Amount'
--            , "Percent" numeric(18, 2) '$.Percent'
--            , Residue numeric(18, 2) '$.Residue'
--        ) js
--        where js.Date in  ('20190411', '20190410', '20190409')
--    )
--    and c.ProductId not in (704239, 686372, 666545, 663887,746807, 664401, 644504, 686595, 665962)
--    and cbn.ActiveAmount != AmountLeft
/

select p.Productid, p.StatusName, AmountLeft
from prd.vw_product p
outer apply
(
    select top 1 lts.ScheduleSnapshot
    from prd.LongTermSchedule lts
    inner join prd.LongTermScheduleLog ltsl on ltsl.ScheduleId = lts.Id
    where lts.ProductId = p.Productid
    order by ltsl.StartedOn desc
) ss
outer apply
(
    select 
        sum(Amount) as AmountLeft
        , min(case when Date >= '20190412' then Date end) as NextDate 
    from openjson(ss.ScheduleSnapshot) with
    (
        Date date '$.Date'
        , Amount numeric(18, 2) '$.Amount'
        , "Percent" numeric(18, 2) '$.Percent'
        , Residue numeric(18, 2) '$.Residue'
    ) js
    where Date >= '20190412'
) s 
where p.Productid in 

(743666,745569,688421)
/

select 
    p2.Productid
    , case
        when cbp.TotalDebt = 0 then N'Погашен'
        when cbp.TotalDebt = cbp.Commission
        then N'Долг по комиссии'
        when cbp.OverdueAmount + cbp.OverduePercent + cbp.Fine > 0
        then N'Просрочен'
        when cbp.OverdueAmount + cbp.OverduePercent + cbp.Fine = 0
        then N'Активен'
    end as OldStatus
    , p2.StatusName as CurrentStatus
from prd.vw_product p2
inner join dbo.br7964 b on b.ProductId = p2.productid
outer apply
(
    select top 1
        cb.DateOperation
        , (cb.ActiveAmount + cb.RestructAmount) * -1 as ActiveAmount
        , (cb.ActivePercent + cb.RestructPercent) * -1  as ActivePercent
        , (cb.OverdueAmount + cb.OverdueRestructAmount) * -1 as OverdueAmount
        , (cb.OverduePercent + cb.OverdueRestructPercent) * -1 as OverduePercent
        , cb.Fine * -1 as Fine
        , cb.Commission * -1 as Commission
        , cb.TotalDebt * -1 as TotalDebt
    from dbo.br7964CreditBalance cb
    where cb.ProductId = b.ProductId
        and cb.InfoType = 'debt'
    order by cb.DateOperation desc 
) cbp
outer apply
(
    select top 1
        cb.DateOperation
        , (cb.ActiveAmount + cb.RestructAmount) * -1 as ActiveAmount
        , (cb.ActivePercent + cb.RestructPercent) * -1  as ActivePercent
        , (cb.OverdueAmount + cb.OverdueRestructAmount) * -1 as OverdueAmount
        , (cb.OverduePercent + cb.OverdueRestructPercent) * -1 as OverduePercent
        , cb.Fine * -1 as Fine
        , cb.Commission * -1 as Commission
    from bi.CreditBalance cb
    where cb.ProductId = p2.Productid
        and cb.InfoType = 'debt'
    order by cb.DateOperation desc
) cbn
    /
select *
from dbo.br7964CreditBalance
where ProductId = 637534
and InfoType = 'debt'
/
select distinct Date
from bi.CollectorGroupHistory
where Date = '20190412'

