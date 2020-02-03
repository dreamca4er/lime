
declare
    @Workers int = 1
    , @PackSize int = 100
    , @CheckSuspended bit = 1
    , @CurrentDate date = cast(getdate() as date)
;

with a as
(
    select
        prod.Productid
        , ol.OperationDate
        , dense_rank() over (order by ol.OperationDate) as WorkerNum
        , row_number() over (partition by ol.OperationDate order by ol.ProductId) as ProductNum
    from prd.vw_product prod
    inner join prd.Product p on p.Id = prod.Productid
    inner join stage.dbo.ProductsToCalc ptc on ptc.Productid = prod.Productid
    inner join prd.OperationLog ol on ol.ProductId = prod.Productid
        and ol.CommandType = 'Prd.Domain.Commands.MoneySentCommand, Prd.Domain, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null'
    where 1=1
        and 0=0
        and prod.ProductType = 1
--        and prod.Status = 5
        and not exists
        (
            select 1 from acc.vw_acc aa
            where aa.ProductId = prod.Productid
                and aa.ProductType = prod.ProductType
                and aa.Number like '48801%'
                and aa.DateClose is not null
        )
        and
        (
            prod.CalcStatus = 0 and @CheckSuspended = 1
            or
            prod.CalcStatus != 2 and @CheckSuspended = 0
        )
        and
        (
            not exists
            (
                select 1 from prd.OperationLog ol
                where ol.ProductId = prod.ProductId
                    and ol.Suspended = 1
            )
            and @CheckSuspended = 1
            or @CheckSuspended = 0
        )
)

select a.OperationDate, count(*)
from a
group by a.OperationDate
/

    select a.*, ol.OperationDate, c.EarlyRepaymentDate
    from a
    left join prd.OperationLog ol on ol.ProductId = a.ProductId
        and ol.CommandType like '%repay%'
    left join stage.dbo.ERD c on c.Productid = a.Productid
    outer apply
    (
        select top 1 StartedOn, Status
        from prd.vw_statusLog sl
        where sl.ProductId = a.ProductId
            and sl.StartedOn < ol.OperationDate
        order by sl.StartedOn desc
    ) st
    /
    where exists
        (
            select 1 from stage.dbo.sop
            where sop.CreditId = a.Productid
                and cast(sop.Date as date) > cast(c.DatePaid as date)
        )
--        and ol.OperationDate is null

/
--insert prd.OperationLog (OperationDate,CommandType,ProductId,CommandSnapshot,Suspended,Number)
select
    b.EarlyRepaymentDate as OperationDate
    , CommandType
    , b.ProductId as ProductId
    , json_modify(json_modify(
            ol.CommandSnapshot, '$.OperationDate', convert(nvarchar(50), b.EarlyRepaymentDate, 126))
            , '$.ProductId', b.ProductId) as CommandSnapshot
    , Suspended
    , 1 as Number
from b, prd.OperationLog ol
where ol.ProductId = 123331
    and ol.CommandType like '%repay%'
--    and b.ProductId = 156136
/


with js as 
(
    select 
        lts.Id
        , ss."key" as Ord
        , json_modify(json_modify(json_modify(ss.value
            , '$.PercentPerDay', p.PercentPerDayWithoutDiscount)
            , '$.PercentPerDayWithDiscount', p.PercentPerDayWithoutDiscount)
            , '$.PercentPerDayWithoutDiscount', p.PercentPerDayWithoutDiscount) as Snap
    from prd.LongTermSchedule lts
    outer apply openjson(ScheduleSnapshot) ss
    inner join stage.dbo.ProductsToCalc ptc on ptc.Productid = lts.ProductId
    inner join prd.vw_product p on p.Productid = lts.ProductId
    where lts.ProductId != 116424
)

select
    lts.ScheduleSnapshot
    , '[' + stuff(ns.NewSnapShot, 1, 1, '') + ']' as NewScheduleSnapshot 
--update lts
--set lts.ScheduleSnapshot = '[' + stuff(ns.NewSnapShot, 1, 1, '') + ']'
from prd.LongTermSchedule lts
inner join stage.dbo.ProductsToCalc ptc on ptc.Productid = lts.ProductId
outer apply
(
    select ',' + Snap as 'text()'
    from js
    where js.Id = lts.Id
    order by js.Ord
    for xml path('')
) as ns(NewSnapShot)
where lts.ProductId != 116424
/

--update prd.OperationLog set Suspended = 0 where ProductId = 116424

/
117893
119100
121235

select ptc.Productid, a.Number, a.DateClose -- select count(distinct acc.productid)
--update a set a.DateClose = null
from acc.vw_acc acc
inner join acc.Account a on a.Id = acc.accountId
inner join stage.dbo.ProductsToCalc ptc on ptc.Productid = acc.ProductId
where 1=1
    and acc.ProductType = 2
    and a.DateClose is not null
    and acc.ProductId in (125241)
    (
    
121235
, 119100
, 117893
, 116703
, 164073
, 218705
, 249178
, 122448
, 123331
    )
/

select *
--into stage.dbo.ProductSettingBak
-- update ps set ValueSnapshot = '0.0'
from prd.ProductSetting ps
where SettingType = 31
    and Started <= '2019-01-25'

select Value
from cache.state
where "key" = 'Recalculation'

    
select sum(cast(ol.Suspended as int)), sum(distinct p.CalcStatus)-- update ol set Suspended = 0-- update p set CalcStatus = 0
from prd.OperationLog ol
inner join prd.Product p on p.Id = ol.ProductId
inner join stage.dbo.ProductsToCalc ptc on ptc.ProductId = p.Id
where (p.CalcStatus != 0 or ol.Suspended != 0)
    and ptc.ProductId in (117893)
       
select *--, json_modify(ol.CommandSnapshot, '$.OperationDate', convert(nvarchar(50), dateadd(d, 1, OperationDate), 126))
-- update ol set OperationDate = dateadd(d, 1, OperationDate), CommandSnapshot = json_modify(ol.CommandSnapshot, '$.OperationDate', convert(nvarchar(50), dateadd(d, 1, OperationDate), 126))
from prd.OperationLog ol
where ProductId = 125241
    and CommandType like '%repay%'
    
/

select p.CalcStatus, p.*
from stage.dbo.ProductsToCalc ptc
inner join prd.vw_product p on p.Productid = ptc.Productid
where 1=1
    and p.Status != 5 
    or exists
    (
        select 1 from acc.vw_acc acc
        inner join acc.Account a on a.Id = acc.accountId
        where acc.ProductId = ptc.Productid
            and acc.ProductType = 2
            and a.DateClose is null
            and a.Number like '48801%'
    )
    
    
    or p.CalcStatus = 2
    
/





declare
    @ProductId int = 121235
    , @OperationDate datetime2 = dateadd(hh, 1, '2017-11-11 04:44:15.767')

--insert prd.OperationLog (OperationDate,CommandType,ProductId,CommandSnapshot,Suspended,Number)
select
    @OperationDate as OperationDate
    , CommandType
    , @ProductId as ProductId
    , json_modify(json_modify(
            ol.CommandSnapshot, '$.OperationDate', convert(nvarchar(50), @OperationDate, 126))
            , '$.ProductId', @ProductId) as CommandSnapshot
    , Suspended
    , 1 as Number
from prd.OperationLog ol
where ProductId = 123331
    and CommandType like '%repay%'

/

select ol.*
-- update ol set OperationDate = dateadd(d, 1, OperationDate), CommandSnapshot = json_modify(ol.CommandSnapshot, '$.OperationDate', convert(nvarchar(50), dateadd(d, 1, OperationDate), 126))
from prd.OperationLog ol
where 1=1
    and CommandType like '%repay%'
    and ol.ProductId = 249178



/

select *
-- update ps set ValueSnapshot = '0.0'
from prd.ProductSetting ps
inner join stage.dbo.ProductSettingBak bak on ps.id = bak.id

select *
from acc.OperDaySettingLog
where Setting = 2

select
    bak.ValueSnapshot
    , ps.ValueSnapshot
-- update ps set ps.ValueSnapshot = bak.ValueSnapshot
from stage.dbo.ProductSettingBak bak
inner join prd.ProductSetting ps on ps.id = bak.id
/
select *
from stage.dbo.ProductSettingBak 
select *
from acc.vw_mm
where ProductId = 137713

select *
from acc.ProductSumJournal
where ProductId = 137713
    and ProductType = 2
    
select *
from prd.OperationLog
where ProductId = 125190  
and CommandType like '%repay%'

/
select DebtorProhibitInteractionType, count(*)
from client.Client c
inner join prd.Product p on p.ClientId = c.Id
inner join stage.dbo.ProductsToCalc ptc on ptc.Productid = p.Id
group by DebtorProhibitInteractionType

select *
from openjson('[155945, 155981, 155993, 155996, 156136, 156144, 156191, 156226, 156349, 156559]') l
inner join prd.Product p on p.Id = l.value
inner join client.Client c on c.Id = p.ClientId
/
select *
from client.Client
where Id = 495393

select a.*-- update a set DateOpen = dateadd(d, -3, DateOpen)
from acc.Account a
inner join acc.ProductAccount pa on pa.AccountId = a.Id
    and pa.ProductType = 2
where pa.ProductId = 161768
    and Number = '60322810000000495393'
select top 10 *
from prd.Product
where ProductType = 2
/
select
    ptc.Productid
    , cast(p.DatePaid as date) as DatePaid
from stage.dbo.ProductsToCalc ptc
inner join prd.vw_product p on p.Productid = ptc.Productid
    and p.StartedOn <= '20171231'
    and p.DatePaid > '20180101'
/
select ptc.Productid, c.EarlyRepaymentDate
from "KONGA-DB".Limezaim_Website.dbo.ProductsToCalc ptc
inner join "KONGA-DB".Limezaim_Website.dbo.Credits c on c.Id = ptc.Productid
left join prd.OperationLog ol on ol.ProductId = ptc.ProductId
    and ol.CommandType = 'Prd.Domain.Commands.RepaymentCommand, Prd.Domain, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null'
where c.EarlyRepaymentDate is not null
    and exists 
    (
        select 1 from "KONGA-DB".Limezaim_Website.dbo.ScheduleOfPayments sop
        where sop.CreditId = ptc.Productid
            and cast(c.Datepaid as date) < sop.Date
    )
    and not exists
        (
            select 1 from prd.OperationLog ol2
            where ol2.ProductId = ol.ProductId
                and ol2.CommandType = 'prd.Domain.Commands.MoneySentCommand, Prd.Domain, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null'
                and ol2.OperationDate < ol.OperationDate
        )
/
select *
from "KONGA-DB".Limezaim_Website.dbo.Credits
where 
select ol.ProductId
from prd.OperationLog ol
inner join stage.dbo.ProductsToCalc ptc on ptc.Productid = ol.ProductId
where CommandType = 'Prd.Domain.Commands.MoneySentCommand, Prd.Domain, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null'
    and exists
    (
        select 1 from prd.OperationLog ol2
        where ol2.ProductId = ol.ProductId
            and ol2.CommandType = 'Prd.Domain.Commands.RepaymentCommand, Prd.Domain, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null'
            and ol2.OperationDate < ol.OperationDate
    )
    /
select 
    c.UserId as ClientId
    , ptc.Productid
    , p.ContractNumber
    , cast(c.DatePaid as date) as OldDatePaid
    , cast(p.DatePaid as date) as NewDatePaid
    , datediff(d, cast(p.DatePaid as date), cast(c.DatePaid as date)) as DaysDiff
    , iif(year(c.DatePaid) != year(p.DatePaid), 1, 0) as IsYearDifferent
from stage.dbo.ProductsToCalc ptc
inner join prd.vw_product p on p.ProductId = ptc.Productid
left join "KONGA-DB".Limezaim_Website.dbo.Credits c on c.Id = ptc.Productid