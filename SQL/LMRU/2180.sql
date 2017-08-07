select 
  qpr.TxnId,
  qpr.PaymentResult,
  p.Id as PaymentId,
  p.Status,
  p.Amount
from QiwiPaymentRequests qpr
left join Payments p on p.QiwiPaymentId = qpr.Id
where TxnId in
(
  select 
    TxnId/*, 
    count(*) as total,
    count(case when PaymentResult = 2 then 1 else null end) as successes
*/
  from QiwiPaymentRequests
  where DateCreated >= '20170501'
    and DateCreated < '20170601'
  group by TxnId, cast(DateCreated as date)
  having count(case when PaymentResult = 2 then 1 else null end) > 1
)
order by qpr.TxnId
/
with statuses as (
select
  'Payment' as Name,
  Value,
  Description
from EnumDescriptions 
where Name = 'PaymentStatus'
union
select 'Qiwi', 0, 'NotRun' union
select 'Qiwi', 1, 'NoAnswerFromAgent' union
select 'Qiwi', 2, 'Success' union
select 'Qiwi', 3, 'PaymentError' union
select 'Qiwi', 4, 'NeedCheck' 
)
select
  p.Id as Paymentid,
  qpr.TxnId,
  p.Status as PaymentStatus,
  ps.Description as paymentStatus,
  qpr.PaymentResult as QiwiStatus,
  pq.Description as qiwiStatus
  
from Payments p
join QiwiPaymentRequests qpr on p.QiwiPaymentId = qpr.Id
left join statuses ps on ps.Value = p.Status
  and ps.name = 'Payment'
left join statuses pq on pq.Value = qpr.PaymentResult
  and pq.name = 'Qiwi'
where qpr.DateCreated >= '20170501'
  and qpr.DateCreated < '20170601'
  and qpr.TxnId not in ('20362883084008')
/*
  and p.Status = 3
  and qpr.PaymentResult != 2
*/
  and qpr.TxnId in
(
'20414200520008',
'20414211331008',
'20414537487008',
'20422311120008'
)
order by qpr.TxnId
/
with qiwi as (
select 
  cast(DateCreated as date) as dt, 
  sum(cast(ResponseXml as xml).value('(/response/sum)[1]', 'numeric(18, 2)')) as summ
from QiwiPaymentRequests qpr
where qpr.DateCreated >= '20170501'
  and qpr.DateCreated < '20170601'
  and qpr.TxnId not in ('20362883084008')
  and PaymentResult = 2
group by cast(DateCreated as date)
)
,pay as (
select 
  cast(DateCreated as date) as dt, 
  sum(Amount) as summ
from Payments p
where id not in 
(
10182224,
10182221,
10182700,
10197417,
10034464,
10034528
)
  and Status = 3
  and DateCreated >= '20170501'
  and DateCreated < '20170601'
  and QiwiPaymentId is not null
  and p.Way > 0
group by cast(DateCreated as date)
)
select
  q.dt,
  q.summ as qiwiSum,
  p.summ as paymentsSum
from qiwi q
join pay p on p.dt = q.dt
where q.summ != p.summ

/
select *
from QiwiPaymentRequests
where TxnId = '20422311120008'
/

20422311120008
20414537487008
20414211331008
20414200520008
/
select *
from Payments
where QiwiPaymentId = 106070

select *
from CreditPayments
where PaymentId = 10197417

105979
105981

