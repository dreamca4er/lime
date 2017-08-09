-- 1. ����� ���������, ���������� � ����
-- 2. ����� �� ��������� �� ������������ ������
-- 3. ����� ��������� �� �1 ������ �����, ����� ��� 4�� ���� � ��������� �� ���� �������� �� �����������
-- 4. ����� ������� (1.07 - 29.07) �� ��������� �� ����. ��������: 
--1 ����: ������� � ��� ���� �� ������, ����������� � ��������� ����������� �1 � ��������� �� 2.06 �� 30.06
--2 ����: ������� � ��� ���� �� ������, ����������� � ��������� ����������� �1 � ��������� �� 3.06 �� 30.06
--...
--29 ����: ������� � ��� ���� �� ������, ����������� � ��������� ����������� �1 30.06

--declare @cred int = 37819;

with nums as (
select 1 as a union all
select 1 as a union all
select 1 as a union all
select 1 as a union all
select 1 as a union all
select 1 as a union all
select 1 as a union all
select 1 as a union all
select 1 as a union all
select 1 as a 
)

,cj as (
select
  row_number() over (order by n1.a) - 1 as rn
from nums n1
cross join nums n2
)

select
  dateadd(d, rn, '20170601') as dt
into #dates
from cj
where dateadd(d, rn, '20170601') < '20170701'


select distinct
  cast(dch.DateCreated as date) as collectorDate,
  d.Id as debtorId,
  fu.Id as userId,
  fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio,
  c.id as creditId,
  c.Period,
  cast(c.DateCreated as date) as creditStarted,
  cast(dateadd(d, c.Period, c.DateCreated) as date) as creditFinalPre
into #cte_creditsPre
from dbo.DebtorCollectorHistory dch
join dbo.Debtors d on d.Id = dch.DebtorId
join dbo.Credits c on c.Id = d.CreditId
join dbo.FrontendUsers fu on fu.Id = c.UserId
where CollectorId in (select UserId
                      from CmsContent_LimeZaim.dbo.UserGroupLinks
                      where UserGroupId = 44)
    and dch.DateCreated >= '20170601'
    and dch.DateCreated < '20170701'


select
    csh.id
    ,csh.CreditId
    ,csh.Status
    ,cast(csh.DateStarted as date) statusStart
    ,row_number() over (partition by csh.CreditId order by csh.DateStarted) as rn
into #cs
from dbo.CreditStatusHistory csh
where csh.CreditId in (select creditId from #cte_creditsPre)
;

with nextStatusPre as
(
    select *
    from #cs cs
    where exists (select 1 from #cs cs1
                  where cs1.CreditId = cs.CreditId
                     and cs1.rn = cs.rn - 1
                     and cs1.Status != cs.status)
      or cs.rn = 1
)

select
    nsp.*
    ,cast(nextStatus.statusStart as date) as statusEnd
into #creditStatuses
from nextStatusPre nsp
outer apply 
(
    select min(nsp1.id) as id
    from nextStatusPre nsp1
    where nsp1.CreditId = nsp.CreditId
        and nsp1.id > nsp.id
) nsp1
left join nextStatusPre nextStatus on nextStatus.id = nsp1.id
;

with debt as 
(
    select
        cs.creditid
        ,cp.debtorid
        ,cp.userid
        ,cs.statusStart as overdueStart
        ,cs.statusEnd as overdueEnd
        ,cp.collectorDate
        ,cb.Amount as amountDebt
        ,cb.PercentAmount + cb.CommisionAmount + cb.PenaltyAmount + cb.LongPrice + cb.TransactionCosts as otherDebt
    from #creditStatuses cs
    inner join #cte_creditsPre cp on cp.CreditId = cs.CreditId
        and datediff(d, cs.statusStart, cp.collectorDate) + 1 = 4
        and (cs.statusEnd is null or statusEnd >= cp.collectorDate)
    left join dbo.CreditBalances cb on cb.CreditId = cp.creditid
        and cb.Date = dateadd(d, -1, cp.collectorDate)
    where cs.status = 3
--        and cs.creditid = @cred
)

,pays as 
(
    select
        cp.CreditId
        ,cast(cp.DateCreated as date) as paymentDate
        ,cp.Amount as amountPaid
        ,cp.PercentAmount as PercentAmountPaid
        ,cp.CommissionAmount as CommissionAmountPaid
        ,cp.PenaltyAmount as PenaltyAmountPaid
        ,cp.LongPrice as LongPricePaid
        ,cp.TransactionCosts as TransactionCostsPaid
        ,row_number() over (partition by cp.CreditId order by cp.id desc) as rn
    from dbo.CreditPayments cp
    inner join dbo.Payments p on p.Id = cp.PaymentId
        and p.Way != 6
    where exists 
        (
            select 1 from debt
            where debt.CreditId = cp.CreditId
                and cp.DateCreated >= debt.collectorDate
        )
        and cp.DateCreated >= '20170601'
        and cp.DateCreated < '20170801'
)

select
    p.paymentDate as "����"
    ,sum(p.amountPaid) as "���� ��������"
    ,sum(p.PercentAmountPaid) as "�������� ��������"
    ,sum(p.CommissionAmountPaid) as "�������� ��������"
    ,sum(p.PenaltyAmountPaid) as "������ ��������"
    ,sum(p.LongPricePaid) as "��������� ��������"
    ,sum(p.TransactionCostsPaid) as "�����. �������� ��������"
    ,null as "���� �� ����"
    ,null as "������ ����"
    ,null as "����� ����"
from pays p
where p.paymentDate >= '20170701'
    and p.paymentDate < '20170730'
    and exists (select 1 from debt d
                where d.creditid = p.creditid
                    and d.collectordate >= dateadd(d, -29, paymentDate)
                    and d.collectordate <= '20170630')
--    and p.creditid = 28969
group by p.paymentDate

union

select 
    null as "����"
    ,null
    ,null
    ,null
    ,null
    ,null
    ,null
    ,ad.amountDebt
    ,sum(cb.PercentAmount + cb.CommisionAmount + cb.PenaltyAmount + cb.LongPrice + cb.TransactionCosts) 
    + sum(pay.percentPayments) as otherDebt
    ,ad.amountDebt
    + isnull(sum(cb.PercentAmount + cb.CommisionAmount + cb.PenaltyAmount + cb.LongPrice + cb.TransactionCosts), 0)
    + sum(pay.percentPayments) as allDebt
from (select sum(amountDebt) as amountDebt from debt) ad, dbo.CreditBalances cb
outer apply 
(
    select isnull(sum(p.PercentAmountPaid), 0) as percentPayments
    from pays p
    inner join dbo.Credits c on c.Id = p.CreditId
    where p.creditid = cb.creditid
        and p.paymentDate >= (select min(d1.collectordate) 
                              from debt d1
                              where d1.creditid = p.creditid)
        and p.rn != case when c.DatePaid < '20170730' then 1 else 0 end
    
) pay
where cb.CreditId in (select creditid from debt/* where debt.creditid = 28969*/)
    and cb.id = (select max(cb1.id)
                   from dbo.CreditBalances cb1
                   where cb1.CreditId = cb.CreditId
                       and cb1.date < '20170730'
                       and cb1.Amount 
                           + cb1.PercentAmount 
                           + cb1.CommisionAmount 
                           + cb1.PenaltyAmount 
                           + cb1.LongPrice 
                           + cb1.TransactionCosts > 0)
group by ad.amountDebt
order by "����"

drop table #creditStatuses
drop table #cs
drop table #cte_creditsPre
drop table #dates
