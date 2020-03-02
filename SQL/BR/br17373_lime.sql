--drop table if exists #arch
--;
--with r as 
--(
--    select
--        r.Id
--        , r.DateB
--        , r.DateE
--        , r.Status
--    from "SRV-BI".Reports.dbo.Report r
--    where r.ProjectId = 1
--        and r.IsArchiveStatus = 2
--        and r.DateB = '20190101'
--)
--
--select
--    r.DateE
--    , rd.ProductId
--    , rd.DatediffContractDatePaid as OverdueDays
--    , isnull(rd.ActiveAmt, 0) as ActiveAmt
--    , isnull(rd.OverdueAmt, 0) as OverdueAmt
--    , isnull(rd.ActivePct, 0) as ActivePct
--    , isnull(rd.OverduePct, 0) as OverduePct
--into #arch
--from r
--inner join dbo.ReportDetail rd on rd.ReportId = r.Id
--where not exists
--    (
--        select 1 from r r2
--        where r.DateE = r2.DateE
--            and r2.Id > r.Id
--    )
--;

drop table if exists #dd
select 
    dd.ProductId
    , po.DateOperation as DiscountDate
into #dd
from acc.DiscountDocuments dd
inner join acc.Document d on d.Id = dd.DocId
inner join acc.ProductOperation po on po.Id = d.ProductOperationId
where po.DateOperation >= '20190101'
    and po.DateOperation < '20200101'
;

alter table #dd alter column ProductId int not null
alter table #dd add primary key (ProductID)
;

with m as 
(
    select top 12 
        dateadd(month, row_number() over (order by 1/0), eomonth('20181231')) as Date
    from sys.objects
)

, p as 
(
    select
        concat(c.LastName, ' ', c.FirstName, ' ', c.FatherName) as "ФИО/Наименование заемщика"
        , left(c.Passport, 4) as "Серия паспорта"
        , right(c.Passport, 6) as "Номер паспорта"
        , N'ФЛ' as "Тип клиента (ФЛ/ИП/ЮЛ)"
        , c.INN as "ИНН"
        , N'Онлайн-микрозайм' as "Вид займа (микрозайм/онлайн-микрозайм/иные займы/ доп. соглашение)"
        , N'Нет' as "Субъект МСП (Да/Нет)"
        , p.ContractNumber as "Номер договора займа/ дополнительного соглашения"
        , N'б/н от ' + format(isnull(dd.DiscountDate, long.BuiltOn), 'dd.MM.yyyy') 
            + N' к договору ' + p.ContractNumber as "Доп. соглашение к договору займа №"
        , case
            when dd.DiscountDate is not null
            then N'Уменьшение процентной ставки'
            when long.BuiltOn is not null
            then N'Увеличение срока договора'
        end as "Содержание доп. соглашения"
        , cast(p.CreatedOn as date) as "Дата заключения договора займа"
        , p.Amount as "Сумма займа по договору (доп. соглашению) в рублях"
        , p.Period as "Срок займа в днях по договору (продление по доп. соглашению на)"
        , p.ContractPayDay as "Дата погашения по договору"
        , dateadd(d, long.Period - 1, long.StartedOn) as "Дата погашения по договору с учетом реструктуризации (при наличии)"
        , p.Psk as "Процентная ставка в процентах годовых"
        , addr.Address as "Территория выдачи (наименование города/населенного пункта, прописка в соответствии с паспортными данными для онлайн-займов)" 
        , null as "Наличие договора залога или поручительства (залог/поручительство/отсутствует)"	
        , null as "Описание предмета залога"	
        , null as "Стоимость залога"	
        , null as "ФИО/наименования залогодателя/ поручителя"	
        , null as "ИНН залогодателя/поручителя"	
        , i.InsuranceCost as "Стоимость страхования (при наличии)"
        , arch.FirstOverdueStart as "Дата образования просроченной задолженности по договору"
        , p.ProductId
        , p.clientid
        , s.Status
        , s.StartedOn
    from prd.vw_product p
    inner join client.vw_Client c on c.clientid = p.ClientId
    left join prd.vw_Insurance i on i.LinkedLoanId = p.Productid
        and i.Status = 2
    outer apply
    (
        select top 1 a.Address
        from client.vw_address a
        where a.ClientId = p.ClientId
        order by a.AddressType desc
    ) addr
    outer apply
    (
        select top 1 arch.StartedOn as FirstOverdueStart
        from bi.ProductStatusArchive arch
        where arch.ProductId = p.ProductId
            and arch.Status = 4
        order by arch.ArchiveDate, StartedOn 
    ) arch
    outer apply
    (
        select dd.DiscountDate
        from #dd dd
        where dd.ProductId = p.ProductId
    ) dd
    outer apply
    (
        select top 1
            long.Period
            , long.BuiltOn
            , long.StartedOn
        from prd.vw_Prolongation long
        where long.ProductId = p.Productid
        order by long.BuiltOn desc
    ) long
    outer apply
    (
        select top 1 
            s.Status
            , s.StartedOn
        from prd.vw_statuslog s
        where s.ProductId = p.productId
            and s.StartedOn <= '20190131'
        order by s.StartedOn desc
    ) s
    where cast(p.CreatedOn as date) >= '20190131' -- Позже исключим займы, которые не попали в портфель  
        or
        (
            cast(p.CreatedOn as date) < '20190131'
            and s.Status not in (1, 5, 7, 8)
        )
)

select Status, StartedOn
from p
/
/*
,od as 
(
    select
        p.ProductID
        , m.Date
        , iif(comp.Status = 4, datediff(d, comp.StatusStart, m.Date) + 1, 0) as OverdueDays
    from p
    cross apply m
    outer apply
    (
        select top 1
            arch.Status
            , arch.StartedOn as StatusStart
        from bi.ProductStatusArchive arch
        where arch.ProductId = p.ProductId
            and arch.StartedOn <= m.Date
            and arch.ArchiveDate <= m.Date
        order by arch.ArchiveDate desc, StartedOn desc
    ) arch
    outer apply
    (
        select top 1
            arch.Status
            , arch.StartedOn as StatusStart
        from bi.ProductStatusArchive arch
        where arch.ProductId = p.ProductId
            and arch.StartedOn <= m.Date
        order by arch.ArchiveDate, StartedOn desc
    ) archdef
    outer apply
    (
        select 
            isnull(arch.Status, archdef.Status) as Status
            , isnull(arch.StatusStart, archdef.StatusStart) as StatusStart
    ) comp
)


,piv as 
(
    select
        PivotTable.*
    from od
    pivot  
    (  
    max(od.OverdueDays)  
    for od.Date in (    
        "2019-01-31"
        , "2019-02-28"
        , "2019-03-31"
        , "2019-04-30"
        , "2019-05-31"
        , "2019-06-30"
        , "2019-07-31"
        , "2019-08-31"
        , "2019-09-30"
        , "2019-10-31"
        , "2019-11-30"
        , "2019-12-31")  
    ) AS PivotTable
)
*/
insert into borneo.dbo.br17373_3
select *
--into borneo.dbo.br17373_3
from p