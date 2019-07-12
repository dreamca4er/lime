--exec sp_rename 'dbo.br12178cred30.PhonenNumber', 'PhoneNumber'
select
    c.clientid as "Id клиента"
    , c.fio as "ФИО"
    , b.PhoneNumber as "Телефон"
    , c.Email
    , c.Timezone as "Таймзона GMT"
    , ma.MaxAmount as "Макс сумма по тарифу"
    , promo.PromocodeDiscount as "Макс скидка по промокоду"
    , loyal.LoyaltyDiscount as "Скидка по ПЛ"
from dbo.br12178nocred100 b
left join prd.vw_product p on p.ClientId = b.ClientId
    and p.Status > 2
    and p.status != 5
left join client.vw_client c on c.clientid = b.ClientId
cross apply
(
    select max(th.MaxAmount) as MaxAmount  
    from client.vw_TariffHistory th
    where th.ClientId = b.ClientId
        and th.IsLatest = 1    
) ma
outer apply
(
    select max(1 - rf.Factor) * 100 as PromocodeDiscount
    from mkt.ClientReductionFactor crf
    inner join mkt.PromoCodes pc on pc.Id = crf.ReductionFactorId
    inner join mkt.ReductionFactor rf on rf.Id = pc.Id
    left join mkt.ProductReductionFactor prf on prf.ClientReductionFactorId = crf.id
    where (rf.EndDate is null or rf.EndDate > cast(getdate() as date))
        and crf.IsUsed = 0
        and crf.ClientId = b.ClientId
) promo
outer apply
(
    select max(1 - rf.Factor) * 100 as LoyaltyDiscount
    from mkt.ClientReductionFactor crf
    inner join mkt.LoyaltyLevels ll on ll.id = crf.ReductionFactorId
    inner join mkt.ReductionFactor rf on rf.Id = ll.Id
    where crf.ClientId = b.ClientId
) loyal
where p.Productid is null
    and ma.MaxAmount is not null
    