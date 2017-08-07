declare @dateStart date = '20170601';

with cte_sms as (
select
  cast(datecreated as date) as date,
  count(*) as smsCnt
from smsmessages with (nolock)
where DateCreated >= @dateStart
group by cast(datecreated as date)
)

,cte_clients as (
select
  cast(DateRegistred as date) as date,
  count(*) as registeredUsersCnt
from FrontendUsers
where DateRegistred >= @dateStart
group by cast(DateRegistred as date)
)

,cte_cards as (
select
  cast(p.DateCreated as date) as date,
  count(*) as cardsCnt,
  sum(case when p.OrderDescription in (N'Добавление карты', N'Оплата за регистрацию банковской карты') 
           then p.Amount
       end) as cardsPaymentsSum
from cards c
join Payments p on p.Id = c.ConfirmationPaymentId
where p.Status = 3
  and p.DateCreated >= @dateStart
group by cast(p.DateCreated as date)
)

,cte_equifax as (
select 
  date,
  count(*) as credHistCnt
from (select 
        RequestId,
        cast(min(DateIssued) as date) as date
      from EquifaxResponses
      where DateIssued >= '20170601'
      group by RequestId) a
group by date
)

,cte_tariffs as (
select
  cast(DateCreated as date) as date,
  count(*) as tariffsCnt
from UserTariffHistory ush
where not exists (select 1 from UserTariffHistory ush1
                  where ush1.UserId = ush.UserId
                    and ush1.DateCreated < ush.DateCreated)
  and ush.DateCreated >= @dateStart
group by cast(DateCreated as date)
)

,cte_credits as (
select
  cast(c.DateStarted as date) as date,
  count(*) as creditsCnt,
  count(case when cast(fu.DateRegistred as date) = cast(c.DateStarted as date) then 1 end) as todayUsersCreditsCnt,
  sum(amount) as creditSum
from Credits c
join FrontendUsers fu on fu.Id = c.UserId
where c.DateStarted >= @dateStart
  and not exists (select 1 from CreditStatusHistory csh
                  where csh.CreditId = c.id
                    and csh.Status in (5, 8)
                    and cast(csh.DateStarted as date) = cast(c.DateStarted as date)
                    and csh.id = (select max(csh1.id)
                                  from CreditStatusHistory csh1
                                  where csh1.CreditId = csh.CreditId
                                    and cast(csh1.DateStarted as date) = cast(csh.DateStarted as date)))
group by cast(c.DateStarted as date)
)

,cte_payments as (
select 
  cast(cp.DateCreated as date) as date,
  sum(cp.Amount) as amountSum,
  sum(cp.PercentAmount) + sum(cp.PenaltyAmount) as persentAndPenaltySum,
  sum(cp.LongPrice) as longSum
from CreditPayments cp
join Payments p on p.id = cp.PaymentId
where p.OrderDescription not like N'%Виртуальный%'
group by cast(cp.DateCreated as date)

)

,agg as (
select
  convert(date, cl.date, 104) as "Отч. Дата",
  isnull(cte_sms.smsCnt, 0) as "Отпр. SMS",
  cl.registeredUsersCnt as "Сег. клиентов",
  isnull(cte_cards.cardsCnt, 0) as "Привяз. карт",
  isnull(cte_equifax.credHistCnt, 0) as "Получ. КИ",
  isnull(cte_tariffs.tariffsCnt, 0) as "Опр. тариф",
  isnull(cte_credits.creditsCnt, 0) as "Выд. кред.",
  isnull(cte_credits.todayUsersCreditsCnt, 0) as "Сег. кл. кред.",
  isnull(cte_credits.creditSum, 0) as "Выдано, руб",
  isnull(cte_equifax.credHistCnt * 7, 0) as "Стоит КИ, руб",
  isnull(cte_payments.persentAndPenaltySum, 0) as "Погашения (проценты + штрафы)",
  isnull(cte_payments.longSum, 0) as "Продления",
  isnull(cte_payments.amountSum, 0) as "Тело долга",
  isnull(cte_cards.cardsPaymentsSum, 0) as "Привязка, руб"
from cte_clients cl
left join cte_sms on cte_sms.date = cl.date
left join cte_cards on cte_cards.date = cl.date
left join cte_equifax on cte_equifax.date = cl.date
left join cte_tariffs on cte_tariffs.date = cl.date
left join cte_credits on cte_credits.date = cl.date
left join cte_payments on cte_payments.date = cl.date
)

select *
from agg

union

select
  convert(date, '99991231', 104),
  sum("Отпр. SMS"),
  sum("Сег. клиентов"),
  sum("Привяз. карт"),
  sum("Получ. КИ"),
  sum("Опр. тариф"),
  sum("Выд. кред."),
  sum("Сег. кл. кред."),
  sum("Выдано, руб"),
  sum("Стоит КИ, руб"),
  sum("Погашения (проценты + штрафы)"),
  sum("Продления"),
  sum("Тело долга"),
  sum("Привязка, руб")
from agg
order by "Отч. Дата" desc