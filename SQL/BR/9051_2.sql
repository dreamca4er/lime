drop table if exists #pay
;

with pay as 
(
    select
        p.Id as PaymentId
        , p.ContractNumber
        , p.CreatedOn
        , p.Amount
        , row_number() over (partition by p.ContractNumber order by p.CreatedOn) as Num
    from pmt.Payment p
    where p.PaymentStatus = 5
        and p.PaymentDirection = 2
        and p.CreatedOn >= '20190401'
        and p.PaymentWay = 1
)

select *
into #pay
from pay
;

create index IX_pay_ContractNumber on #pay(ContractNumber)
/
with cte(PaymentId,ContractNumber,CreatedOn,Amount,InitialPaymentId,Num, iter) as 
(
    select
        pay.PaymentId
        , pay.ContractNumber
        , pay.CreatedOn
        , pay.Amount
        , pay.PaymentId as InitialPaymentId
        , pay.Num
        , 1 as iter
    from #pay pay
    where not exists
        (
            select 1 from #pay p2
            where p2.ContractNumber = pay.ContractNumber
                and p2.CreatedOn < pay.CreatedOn
                and datediff(s, p2.CreatedOn, pay.CreatedOn) <= 180
        )
    
    union all
    
    select
        pay.PaymentId
        , pay.ContractNumber
        , pay.CreatedOn
        , pay.Amount
        , cte.InitialPaymentId
        , pay.Num
        , cte.iter + 1 as iter
    from cte
    inner join #pay pay on pay.ContractNumber = cte.ContractNumber
        and pay.Amount = cte.Amount
        and datediff(s, cte.CreatedOn, pay.CreatedOn) <= 180
        and pay.Num = cte.Num + 1
)

select 
    cte.InitialPaymentId as "Id первоначального платежа"
    , pay.CreatedOn as "Дата первоначального платежа" 
    , cte.ContractNumber as "Номер договора"
    , p.StatusName as "Статус кредита"
    , p.ClientId as "Id клиента"
    , cl.fio as "ФИО"
    , cte.Amount as "Сумма первоначального платежа"
    , max(iter) as "Количество дублей"
    , a.SaldoNt as "Переплата у клиента"
from cte
inner join prd.vw_Product p on p.ContractNumber = cte.ContractNumber
left join client.vw_client cl on cl.clientid = p.ClientId
left join pmt.Payment pay on pay.id = cte.InitialPaymentId
left join acc.Account a on a.Number = '6032281' + right(replicate('0', 13) + cast(p.ClientId as nvarchar(20)), 13)
where PaymentId is not null
    and exists
    (
        select 1 from cte cte2
        where cte2.InitialPaymentId = cte.InitialPaymentId
            and cte2.iter > 1
    )
group by 
    cte.InitialPaymentId
    , cte.ContractNumber
    , p.ClientId
    , cte.Amount
    , a.SaldoNt
    , p.StatusName
    , pay.CreatedOn
    , cl.fio