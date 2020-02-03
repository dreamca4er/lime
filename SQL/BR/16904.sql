select *
from acc.CessionaryAccount ca
inner join acc.Account a on a.Id = ca.AccountId

--insert acc.Account(    "Number"    , "BalAccountId"    , "CurrencyId"    , "Name"    , "Type"    , "State"    , "DateOpen"    , "Saldo"    , "SaldoNt")
select 
    '60323810000000000098' as Number
    , BalAccountId
    , CurrencyId
    , N'Цессионарий МФК "Лайм-Займ"'
    , Type
    , State
    , DateOpen
    , 0
    , 0
from acc.Account
where Id = 2555918 -- Просто берем для примера

select @@identity
select * -- update a set Number = '60323810000000000121'
from acc.Account a
where id = 3739234
--insert acc.CessionaryAccount(    CessionaryId,Date,AccountId)
select 10, '20100101', 3739234 -- Id Счета для Лаймад

/

select * -- Update a set Name = N'Цессионарий ООО МФК "Лайм-Займ"'
from acc.Account a
where Id = 3739234
/

drop table if exists #except
drop table if exists #prods
;

select br.*, pr.Status
into #except
from stuff.dbo.br16904 br
inner join prd.vw_product pr on pr.Productid = br.ProductId
where exists
    (
        select 1 from acc.vw_mm cb
        where cb.ProductId = br.ProductId
            and cb.ProductType in (1, 2)
            and cb.isDistributePayment = 1
            and cb.DateOperation >= '20191231'
    )
    or exists
    (
        select 1 from acc.vw_acc acc
        where acc.ProductId = br.ProductId
            and acc.ProductType in (1, 2)
            and acc.Number like '47422%'
            and acc.SaldoNt != 0
    )
    or exists
    (
        select 1 from prd.vw_product p
        where p.Productid = br.ProductId
            and p.Status != 4
    )
    or exists
    (
        select 1 from pmt.vw_Payment p
        where p.ContractNumber = br.ContractNumber
            and p.PaymentDirection = 2
            and p.CreatedOn >= '20191231'
    )
    or exists
    (
        select 1
        from prd.LongTermScheduleLog ltsl
        inner join prd.LongTermSchedule lts on lts.Id = ltsl.ScheduleId
        outer apply openjson(lts.ScheduleSnapshot) with (Date date) d
        where not exists
            (
                select 1 from prd.LongTermScheduleLog ltsl2
                where ltsl2.ProductId = ltsl.ProductId
                    and ltsl2.StartedOn > ltsl.StartedOn
            )
            and ltsl.ProductId = br.ProductId
            and d.Date >= '20191231'
    )
;

select *
into #prods
from stuff.dbo.br16904 br
where not exists
    (
        select 1 from #except e
        where e.ProductId = br.ProductId 
    )
;

select 
'{
  "productIds": ['
    + stuff
(
    (
        select top 2000 ',' + cast(ProductId as nvarchar(10)) as 'text()' 
        from #prods br
--        where p.ProductId != 146469
        order by ProductId for xml path('')
    )
, 1, 1, '')
+ ']
,
  "cessionaryId": 10,
  "operationDate": "2020-01-21T04:52:49.4918508",
  "cessionDate": "2019-12-31T00:00:00"}
'

/

select Status, count(*) as cnt
from prd.vw_product
where Productid in (select top 2000 ProductId from #prods order by ProductId)
group by Status
;

select sum(SaldoNt) as CurrentPackDebtNotOnCesseion, (select count(*) from #prods) as TotalProductsLeft
from acc.vw_acc
where ProductId in (select top 2000  ProductId from #prods order by ProductId)
    and ProductType in (1, 2)
    and BalAccountId != 116

/
--insert ecc.Notice(ClientId,Productid,Text,CreatedOn,CreatedBy,TemplateUuid,NoticeType,NoticeShowType,AvailableFrom)
select
    p.ClientId
    , p.Productid
    , replace(replace(replace(replace(replace(ct.Template
        , '{{ContractNumber}}', p.ContractNumber)
        , '{{Fio}}', c.fio)
        , '{{CessionDate}}', '31/12/2019')
        , '{{ContractDate}}', convert(varchar, p.CreatedOn, 103))
        , '{{CreditorCompany}}', N'ООО МФК "МангоФинанс"') as Text
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 'F387233C-FE4F-4767-90EB-ED05CCD8945A' as TemplateUuid
    , 4 as NoticeType
    , 1 as NoticeShowType
    , '1753-01-01 00:00:00.000' as AvailableFrom
from doc.CommunicationTemplate ct, prd.vw_product p
inner join client.vw_client c on c.clientid = p.ClientId
where ct.Uuid = 'F387233C-FE4F-4767-90EB-ED05CCD8945A'
    and p.productid in (select productid from stuff.dbo.br16904)
    and p.Status = 6
    and not exists
    (
        select 1 
        from ecc.Notice n 
        where n.ClientId = p.ClientId
            and n.TemplateUuid = 'F387233C-FE4F-4767-90EB-ED05CCD8945A'
            and n.CreatedOn > = '20200120'
    )
/

select count(*)
from stuff.dbo.br16904 br
inner join prd.vw_product p on p.Productid = br.ProductId
    and p.Status = 6
where exists
    (
        select 1 from collector.OverdueProduct op
        where op.ProductId = br.ProductId
            and op.IsDone = 0
    )