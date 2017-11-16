create table ##lmru3230 
(
    id int
)
/
/*
select *
from dbo.syn_cmsusers
*/
-- Лайм
-- 1229	Для передачи	в суд
-- 1237	не	оформлял
-- 1049	Умершие	Должники

-- Конга
-- 2198	Для	передачи
-- 2234	не	оформлял
-- 1049	Умершие	Должники
drop table if exists ##lmru3230
;

select
    uc.UserId as id
into ##lmru3230
from dbo.UserCards uc
inner join dbo.Credits c on c.UserId = uc.UserId
    and c.Status = 3
where uc.IsFraud = 0
--    and datediff(d, c.PayDay, getdate()) >= 60
--    and datediff(d, c.PayDay, getdate()) <= 116
    and exists
            (
                select 1 from dbo.CreditPaymentSchedules cps
                where cps.CreditId = c.id
                    and datediff(d, cps.Date, getdate()) >= 60
                    and datediff(d, cps.Date, getdate()) <= 116
            )
    and not exists 
                (
                    select 1 from dbo.DebtorCollectorHistory dch
                    inner join dbo.Debtors d on d.Id = dch.DebtorId
--                    where 
                    where 1 = 1
--                        and dch.CollectorId in (2198, 2234, 1049) -- Konga
--                        and dch.CollectorId in (1229, 1237, 1049) -- Lime
                        and c.id = d.CreditId

                )
    and not exists
                (
                    select 1 from dbo.DebtorTransferCession dts
                    inner join dbo.Debtors d on d.Id = dts.DebtorId
                    where d.CreditId = c.id
                )

/
select
    ul.id
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,concat(
        uar.CityName
        ,isnull(', ' + uar.StreetName, '')
        ,', '
        ,uar.House
        ,isnull(', ' + uar.Block, '')
    ) as regaddress
    ,uar.CityName as regCity
    ,coalesce(ks."INDEX", kh."INDEX") as zipcode
    ,left(uc.Passport, 4) as passportSeries
    ,right(uc.Passport, 6) as passportNumber
    ,uc.PassportIssuedOn
    ,uc.PassportIssuedBy
    ,c.DogovorNumber as contract
    ,c.DateCreated as contractDate
    ,cb.Amount + cb.PercentAmount + cb.PenaltyAmount + cb.LongPrice + cb.TransactionCosts as totaldebt
    ,cb.Amount
    ,cb.PercentAmount
    ,cb.PenaltyAmount
    ,cb.LongPrice
    ,cb.TransactionCosts
from ##lmru3230 ul
inner join dbo.Credits c on c.UserId = ul.id
    and c.Status = 3
inner join dbo.FrontendUsers fu on fu.id = ul.id
inner join dbo.UserCards uc on uc.UserId = ul.id
inner join dbo.UserAddresses uar on uar.Id = uc.RegAddressId
inner join dbo.Locations lr on lr.Id = uar.StreetId
left join dbo.KladrStreets ks on ks.CODE = lr.KladrCode
left join dbo.Locations lh on lh.Id = uar.HouseId
left join dbo.KladrHouses kh on kh.CODE = lh.KladrCode
left join dbo.CreditBalances cb on cb.CreditId = c.id
    and cb.Date = cast(getdate() - 1 as date)
--left join dbo.CreditPayments cp on cp.creditid = c.id
--    and cp.DateCreated >= getdate()
/

