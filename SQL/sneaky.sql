-- Разные юзера с одним номером карты

with one_card as (
select 
  c1.FrontendUserId, 
  c.id,
  fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
from Cards c1
join
(
  select 
    c.Holder, 
    c.Expires, 
    c.NumberMasked, 
    dense_rank() over (order by c.Holder, c.Expires, c.NumberMasked) as id
  from Cards c
  where c.Holder not in ('MOMENTUM R', 'MEGAFON CLIENT')
  group by c.Holder, c.Expires, c.NumberMasked--, c.FrontendUserId
  having count(distinct c.FrontendUserId) > 1
) c on c.Holder = c1.Holder
  and c.Expires = c1.Expires
  and c.NumberMasked = c1.NumberMasked
join FrontendUsers fu on fu.Id = c1.FrontendUserId
)

,cred as (
select
  c.id as creditId,
  c.DateStarted,
  c.DatePaid,
  c.Period,
  c.Amount,
  c.UserId,
  oc.id as cardHolderid, 
  oc.fio
from Credits c
join one_card oc on oc.FrontendUserId = c.UserId
where c.Status != 8
)

select 
  c1.*,
  '                       ' as delim,
  c2.*
from cred c1
join cred c2 on c2.cardHolderid = c1.cardHolderid
  and c1.creditId != c2.creditId
  and c1.DateStarted < c2.DatePaid
  and c1.creditId > c2.creditId
  and (c1.DatePaid > c2.DateStarted or c1.DatePaid is null)

/
-- Один СНИЛС
with fishySnils as (
select
  fu.id as Userid,
  fu.EmailAddress,
  fu.MobilePhone,
  uc.Snils,
  fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio,
  uc.Birthday,
  uc.Passport,
  uc.PassportIssuedOn,
  dense_rank() over (order by uc.Snils) as snilsHolderId
from FrontendUsers fu
join UserCards uc on uc.UserId = fu.id
where uc.Snils in (select Snils
                   from UserCards
                   where coalesce(Snils, '') not in ('', '00000000000')
                   group by Snils
                   having count(distinct Passport) > 1)
)

select 
  fs1.*,
  c1.DateStarted,
  c1.DatePaid,
  c1.Period,
  c1.Amount,
  c1.Status,
  c1.IpAddress
from fishySnils fs1
join Credits c1 on c1.UserId = fs1.Userid
  and c1.status != 8
  and c1.DatePaid is null
where snilsHolderId in (select
                          fs.snilsHolderId
                        from Credits c
                        join fishySnils fs on fs.Userid = c.UserId
                        where c.status != 8
                          and c.DatePaid is null
                        group by fs.snilsHolderId
                        having count(*) > 1)

/

with email as (
select
  c1.UserId,
  fu.EmailAddress,
  fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio,
  c1.DateStarted,
  c1.DatePaid,
  c1.Period,
  c1.Amount,
  c1.Status,
  c1.id as creditId
from FrontendUsers fu
join Credits c1 on c1.UserId = fu.Id
  and c1.Status in (1, 3, 5, 6)
where EmailAddress in (select
                         EmailAddress
                       from FrontendUsers fu
                       join Credits c on c.UserId = fu.id
                         and c.Status in (1, 3, 5, 6) 
                       group by EmailAddress
                       having count(*) > 1)
)

select *, 
  case when userid = '485256' then 'LMRU-1886' end as info
from email
where lower(rtrim(ltrim(fio))) in (select lower(rtrim(ltrim(fio)))
                                   from email
                                   group by lower(rtrim(ltrim(fio)))
                                   having count(*) > 1)

/

with requests as (
select
  eqr.UserId,
  max(Id) as id
from EquifaxRequests eqr
--where UserId = 50310
--where id = 529298
group by eqr.UserId
)

,detail as (
select distinct
  req.UserId as equifaxUserId,
  eqpi.DocumentNumber as equifaxPassport,
  uc.Passport as currentUserCardsPassport,
  case when eqpi.Type = 1 then 'Current' else 'History' end as equifaxPassportType
from EquifaxPersonalInfo eqpi with (nolock)
join EquifaxResponses resp with (nolock) on resp.Id = eqpi.ResponseId
join requests req with (nolock) on req.Id = resp.RequestId
join UserCards uc on uc.UserId = req.userid
where eqpi.DocumentType = 1
  --and eqpi.DocumentNumber = '0101662697'
)

,passportDoubles as (
select distinct 
  d.*, 
  uc.UserId as UserWithpassport
from detail d
join UserCards uc on uc.Passport = d.equifaxPassport
  and uc.UserId != d.equifaxUserId
where not exists (select 1 from UserStatusHistory ush
                  where ush.UserId in (d.equifaxUserId, uc.userid)
                    and ush.Status in (6, 12))
)

,passportNotEqualEquifaxCurent as (
select *
from detail
where equifaxPassport != currentUserCardsPassport
  and not exists (select 1 from UserStatusHistory ush
                  where ush.UserId = equifaxUserId
                    and ush.Status in (6, 12))
  and equifaxPassportType = 'Current'
)

,creditDetail as (
select 
  pd.*,
  c.DateCreated as cCreated,
  c.Amount as cAmount,
  c.Status as cStatus,
  c1.DateCreated as c1Created,
  c1.Amount as c1Amounbt,
  c1.Status as c1Status
from passportDoubles pd
left join Credits c on c.UserId = pd.equifaxUserId
  and c.Status in (1, 3, 5, 6)
left join Credits c1 on c1.UserId = pd.UserWithpassport
  and c1.Status in (1, 3, 5, 6)
)

select *
from creditDetail
where cCreated is not null
  and c1Created is not null

/
-- Яндекс
with ya as (
select distinct
  UserId, 
  YandexMoneyAccount
from YandexPaymentRequests
where PaymentResult = 0
  and UserId != 0
  and CreatedByUserId != 0
)

,pay as (
select distinct 
  ypr.UserId,
  ypr.YandexMoneyAccount,
  cp.CreditId,
  c.Status,
  c.DateStarted,
  c.DatePaid
from YandexPaymentRequests ypr 
join Payments p on p.YandexPaymentId = ypr.Id
join CreditPayments cp on cp.PaymentId = p.Id
join Credits c on c.Id = cp.CreditId
where ypr.YandexMoneyAccount in (select YandexMoneyAccount
                                 from ya
                                 group by YandexMoneyAccount
                                 having count(distinct userid) > 1)
)

select
  p1.YandexMoneyAccount,
  p1.userid as user1,
  p2.userid as user2,
  fu1.Lastname + ' ' + fu1.Firstname + isnull(' ' + fu1.Fathername, '') as fio1,
  fu2.Lastname + ' ' + fu2.Firstname + isnull(' ' + fu2.Fathername, '') as fio2,
  uc1.Passport as passport1,
  uc2.Passport as passport2,
  p1.CreditId as credit1,
  p1.Status as creditStatus1,
  p1.DateStarted as started1,
  p1.DatePaid as paid1,
  p2.CreditId as credit2,
  p2.Status as creditStatus2,
  p2.DateStarted as started2,
  p2.DatePaid as paid2
from pay p1
join pay p2 on p1.YandexMoneyAccount = p2.YandexMoneyAccount
  and p1.CreditId > p2.CreditId
  and p1.userid != p2.userid
join FrontendUsers fu1 on fu1.id = p1.UserId
join FrontendUsers fu2 on fu2.id = p2.UserId
join UserCards uc1 on uc1.UserId = fu1.id
join UserCards uc2 on uc2.UserId = fu2.id
order by p1.DateStarted
