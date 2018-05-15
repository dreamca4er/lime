declare
    @dateFrom date = '20180301'
    ,@dateTo date = '20180501'
;

drop table if exists #info
;

select
    p.ContractNumber
    ,p.Productid
    ,c.clientid
    ,c.fio
    ,c.PhoneNumber
    ,case
        when v.VerifierFio is not null then v.VerifierFio
        when v.CreatedBy = cast(0x44 as uniqueidentifier) then N'Акция'
        when v.CreatedBy = cast(0x77 as uniqueidentifier) then N'Скоринг'
        else N'Автоматически'
    end as Verifier
    ,p.TariffName
    ,p.StartedOn
    ,p.Period
    ,p.Amount
    ,p.statusName as ProductStatus
    ,isnull(pay.PaidAmount, 0) as PaidAmount
    ,isnull(pay.PaidPercent, 0) as PaidPercent
    ,isnull(pay.PaidCommission, 0) as PaidCommission
    ,isnull(pay.PaidProlong, 0) as PaidProlong
    ,isnull(pay.PaidFine, 0) as PaidFine
    ,lts.ScheduleSnapshot
into #info
from prd.vw_product p
inner join client.vw_client c on c.clientid = p.clientId
outer apply
(
    select top 1 
        ltt.CreatedBy
        ,a.name as VerifierFio
    from client.UserLongTermTariff ltt
    left join sts.vw_admins a on a.id = ltt.CreatedBy
    where ltt.ClientId = p.clientId
        and ltt.CreatedOn < p.StartedOn
    order by CreatedOn desc
) v
outer apply
(
    select 
        sum(cb.TotalAmount) as PaidAmount
        ,sum(cb.TotalPercent) as PaidPercent
        ,sum(cb.Commission) as PaidCommission
        ,sum(cb.Prolong) as PaidProlong
        ,sum(cb.Fine) as PaidFine
    from bi.CreditBalance cb
    where cb.ProductId = p.productid
        and cb.DateOperation < getdate()
        and cb.InfoType = 'payment'
) pay
outer apply
(
    select top 1 lts.ScheduleSnapshot
    from prd.LongTermSchedule lts
    inner join prd.LongTermScheduleLog ltsl on ltsl.ScheduleId = lts.id
    where lts.ProductId = p.productid
    order by ltsl.StartedOn desc
)  lts
where cast(p.StartedOn as date) between @dateFrom and @dateTo
    and p.productType = 2
    and p.status > 2
;
/
select *
from #info i
outer apply
(
    select
        sum(case when ac.Number like '48801%_1' then ac.SaldoNt else 0 end) * -1 as ActiveAmount
        ,sum(case when ac.Number like '48801%_2' then ac.SaldoNt else 0 end) * -1 as OverdueAmount
        ,sum(case when ac.Number like '48802%_1' then ac.SaldoNt else 0 end) * -1 as ActivePercent
        ,sum(case when ac.Number like '48802%_2' then ac.SaldoNt else 0 end) * -1 as OverduePercent
        ,sum(case when ac.Number like '48803%04' then ac.SaldoNt else 0 end) * -1 as Commission
        ,sum(case when ac.Number like N'Штраф%' then ac.SaldoNt else 0 end) * -1 as Fine
    from acc.vw_acc ac
    where i.productid = ac.productid
        and left(ac.Number, 5) in ('48801', '48802', '48803', N'Штраф')
) cb
cross apply
(
    select 
        count(*) as TotalSchedulePayments
        ,max(Amount + "Percent") as PaymentSum
        ,sum(case when Date < cast(getdate() as date) then Amount + "Percent" end) as PaymentsSumToDate
        ,count(case when Date < cast(getdate() as date) then 1 end) as PaymentsCountToDate
        ,min(case when Date >= cast(getdate() as date) then Date end) as NextPaymentDate
        ,min(case when Date < cast(getdate() as date) then Date end) as LastPaymentDate
        ,ceiling((cb.OverdueAmount + cb.OverduePercent) / sum(case when Date < cast(getdate() as date) then Amount + "Percent" end)) as Debt
    from openjson(i.ScheduleSnapshot)
    with
    (
        Date date '$.Date'
        ,Amount numeric(12, 2) '$.Amount'
        ,"Percent" numeric(12, 2) '$.Percent'
        ,Residue numeric(12, 2) '$.Residue'
    )
) sp
