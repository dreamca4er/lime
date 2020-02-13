/*drop table if exists #osv
;
with osv as 
(
    select
        op.ProductId
        , op.AssignDate
    from col.tf_op('20190101', '20191231') op
    where CollectorGroupId = 6
        and not exists
        (
            select 1 from col.tf_op('20180101', '20191231') op2
            where op2.ProductId = op.ProductId
                and op2.CollectorGroupId = 6
                and op2.AssignDate < op.AssignDate
        )
        and op.AssignDate between '20190101' and '20191231'
)

select *
into stuff.dbo.osv
from osv
;
select *
from stuff.dbo.osv
create clustered index IX_osv_ProductId on stuff.dbo.osv(productId)
/
select  *
from drop table stuff.dbo.osv
create table stuff.dbo.osv
(
    ClientID int
    , ContractNumber nvarchar(20)
    , AssignDate date
    , Cost numeric(18, 2)
)
select *
from stuff.dbo.osv

sp_rename 'dbo.osv.ContarctNumber', 'ContractNumber'

alter table stuff.dbo.osv add ProductId int

select osv.*, p.Id as ProductId
-- update osv set osv.ProductId = p.Id 
from stuff.dbo.osv
left join prd.product p on cast(p.ContractNumber as bigint)= cast(cast(osv.ContractNumber as float) as bigint)
    and p.producttype in (1, 2)
*/
--
/*drop table if exists stuff.dbo.paid
select
    op.productId
    , isnull(sum(cb.PaidNotOsv), 0) as PaidNotOsv
    , isnull(sum(cb.PaidOsv), 0) as PaidOsv
into stuff.dbo.paid
from col.tf_op('19000101', '20191231') op
outer apply
(
    select 
        sum(iif(cb.DateOperation < osv.AssignDate or osv.AssignDate is null,  cb.TotalDebt - cb.Commission, 0)) as PaidNotOsv
        , sum(iif(cb.DateOperation >= osv.AssignDate,  cb.TotalDebt - cb.Commission, 0)) as PaidOsv
    from bi.CreditBalance cb
    left join stuff.dbo.osv on osv.ProductId = cb.ProductId
    where cb.ProductId = op.ProductId
        and cb.InfoType = 'payment'
        and cb.DateOperation between op.AssignDate and op.LastDayWasAssigned
) cb
where AssignDate >= '20180225'
group by op.productId
;

create clustered index IX_paid_ProductId on stuff.dbo.paid(productId)*/

--select top 1 
--    cast(arch.StartedOn as date) as FirstOverdueStart
--from bi.ProductStatusArchive arch
--where arch.ProductId = p.ProductId
--    and arch.Status = 4
--order by arch.ArchiveDate, StartedOn 



with a as 
(
    select *
    from 
    (
        values
        (1254.55821, 2018, 7)
        , (1254.55821, 2018, 8)
        , (1254.55821, 2018, 9)
        , (1254.55821, 2018, 11)
        , (1254.55821, 2018, 10)
        , (1254.55821, 2018, 12)
        , (1186.732941, 2019, 1)
        , (1373.677084, 2019, 2)
        , (1203.264604, 2019, 3)
        , (1001.247939, 2019, 4)
        , (623.6784209, 2019, 5)
        , (1372.781543, 2019, 6)
        , (973.3613749, 2019, 7)
        , (747.4728515, 2019, 8)
        , (539.4809474, 2019, 9)
        , (584.1051738, 2019, 10)
        , (552.5239368, 2019, 11)
        , (506.8235533, 2019, 12)
    ) v(price, y, m)
)

select 
    p.ProductId
    , concat(c.LastName, ' ', c.FirstName, ' ', c.FatherName) as "ФИО/Наименование заемщика"
    , N'ФЛ' as "Тип клиента (ФЛ/ИП/ЮЛ)"
    , c.INN as "ИНН"
    , c.Passport as "Серия и номер паспорта (для ФЛ)"
    , c.BirthDate as "Дата рождения (для ФЛ)"
    , p.ContractNumber as "Номер договора займа"
    , cast(p.CreatedOn as date) as "Дата заключения договора займа"
    , p.Amount as "Сумма займа по договору в рублях"
    , p.Period as "Срок займа в днях по договору в днях"
    , p.ContractPayDay as "Дата погашения по договору"
    , dateadd(d, long.Period - 1, long.StartedOn) as "Дата погашения по договору с учетом реструктуризации (при наличии)"
    , p.Psk as "Процентная ставка в процентах годовых"
    , addr.Address as "Территория выдачи (наименование города/населенного пункта, прописка в соответствии с паспортными данными для онлайн-займов)" 
    , null as "Марка автомобиля"	
    , null as "Год выпуска автомобиля"	
    , null as "Стоимость залога, в рублях"	
    , null as "тношение графы 8 к графе 18, в %"	
    , null as "ИНН залогодателя/поручителя"	
    , arch.FirstOverdueStart as "Дата начала стадии взыскания"
    , 1 as "Количество дней просроченной задолженности в момент начала стадии взыскания"
    , nullif(isnull(cbfo.TotalDebt, ocb.OldOverdueDebt), 0) as "Просроченная задолженность в момент начала стадии взыскания (ОД, %, пени), в рублях"
    , paid.PaidNotOsv as "Сумма просроченной задолженности, которую удалось взыскать, в рублях"
    , dp.DVZPrice as "Затраты на реализацию стадии взыскания, в рублях"
    , isnull(paid.PaidNotOsv, 0) - dp.DVZPrice as "Графа 22 - графа 23, в рублях"
    , (isnull(paid.PaidNotOsv, 0) - dp.DVZPrice) / nullif(isnull(cbfo.TotalDebt, ocb.OldOverdueDebt), 0) as "Отношение графы 24 к графе 21, в %"
    , osv.AssignDate as "Дата начала стадии взыскания"
    , datediff(d, oos.OsvOverdueStart, osv.AssignDate) + 1 as "Количество дней просроченной задолженности в момент начала стадии взыскания"
    , cbfosv.TotalDebt as "Просроченная задолженность в момент начала стадии взыскания (ОД, %, пени), в рублях"
    , paid.PaidOsv as "Сумма просроченной задолженности, которую удалось взыскать, в рублях"
    , isnull(osv.Cost, 0) as "Затраты на реализацию стадии взыскания, в рублях"
    , isnull(paid.PaidOsv, 0) - isnull(osv.Cost, 0) as "Графа 29 - графа 30, в рублях"
    , (isnull(paid.PaidOsv, 0) - isnull(osv.Cost, 0)) / nullif(osv.Cost, 0) as "Отношение графы 31 к графе 28, в %"
    , ocb.OldOverdueDebt
from prd.vw_product p
inner join client.vw_Client c on c.clientid = p.ClientId
left join stuff.dbo.osv on osv.Productid = p.ProductId
left join stuff.dbo.paid on paid.ProductId = p.ProductId
outer apply
(
    select top 1 a.Address
    from client.vw_address a
    where a.ClientId = p.ClientId
    order by a.AddressType desc
) addr
outer apply
(
    select top 1 
        cast(arch.StartedOn as date) as FirstOverdueStart
    from bi.ProductStatusArchive arch
    where arch.ProductId = p.ProductId
        and arch.Status = 4
    order by arch.ArchiveDate, StartedOn 
) arch
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
        (cb.TotalDebt - cb.Commission) * -1 as TotalDebt
    from bi.CreditBalance cb
    where cb.ProductId = p.Productid
        and cb.InfoType = 'debt'
        and cb.DateOperation <= arch.FirstOverdueStart
        and cb.DateOperation >= '20180225'
    order by cb.DateOperation desc
) cbfo
outer apply
(
    select top 1 
        (cb.TotalDebt - cb.Commission) * -1 as TotalDebt
    from bi.CreditBalance cb
    where cb.ProductId = p.Productid
        and cb.InfoType = 'debt'
        and cb.DateOperation <= osv.AssignDate
        and cb.DateOperation >= '20180225'
    order by cb.DateOperation desc
) cbfosv
outer apply
(
    select top 1 
        cast(arch.StartedOn as date) as OsvOverdueStart
        , arch.Status
    from bi.ProductStatusArchive arch
    where arch.ProductId = p.ProductId
        and arch.StartedOn < osv.AssignDate
        and arch.ArchiveDate >= osv.AssignDate
    order by arch.ArchiveDate, StartedOn desc
) oos
left join a on a.y = year(arch.FirstOverdueStart)
    and a.m = month(arch.FirstOverdueStart)
outer apply
(
    select top 1 a.Price as MinPreOSVPrice from a order by y, m 
) mp
outer apply
(
    select coalesce(a.price, mp.MinPreOSVPrice, 0) as DVZPrice
) dp
outer apply
(
    select top 1
        Amount +
        PercentAmount +
        PenaltyAmount as OldOverdueDebt 
    from "OLD-PROJECT-DB".Limezaim_Website.dbo.CreditBalances cb
    where cb.CreditId = p.ProductId
        and dateadd(d, -1, cb.Date) = arch.FirstOverdueStart
        and cbfo.TotalDebt is null
    order by cb.Date desc
) ocb
where p.Status > 2
    and (arch.FirstOverdueStart between '20190101' and '20191231' or osv.Productid is not null)
    and isnull(oos.Status, 4) = 4