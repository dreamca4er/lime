declare
    @NewTokenFirstProduct datetime2
;

-- Находим дату создания первого кредита с нвоым токеном
select @NewTokenFirstProduct = min(mp.CreatedOn)
from bi.MintosData md
inner join mts.MintosProduct mp on mp.ProductId = md.lender_id
;
/*
select mp.Status, ps.Description as StatusName, count(*) as Cnt
from mts.MintosProduct mp
inner join mts.EnumMintosProductState ps on ps.Id = mp.Status
where mp.CreatedOn >= @NewTokenFirstProduct
group by ps.Description, mp.Status
order by mp.Status 
*/
order by mp.Status
-- Выставляем статус Finished все кредитам, созданным до нового токена
select mp.Status, count(*)
-- update mp set Status = 10
from mts.MintosProduct mp
where mp.CreatedOn < @NewTokenFirstProduct
    and mp.Status != 10
group by Status
;

-- Выставляем статус Finished все кредитам с текущим статусом Sent,
-- которые в Mintos значатся как Finished
select mp.Status, md.status, count(*)
-- update mp set Status = 10
from mts.MintosProduct mp
inner join bi.MintosData md on md.lender_id = mp.ProductId 
where 1=1
    and mp.Status = 2
    and md.status = 'finished'
group by mp.Status, md.status
;

-- Выставляем статус Declined все кредитам с текущим статусом Sent,
-- которые в Mintos значатся как Declined
select count(*)
-- update mp set Status = 6
from mts.MintosProduct mp
inner join bi.MintosData md on md.lender_id = mp.ProductId 
where 1=1
    and mp.Status = 2
    and md.status = 'declined'
;

select md.status, count(*)
-- update mp set Status = 4
from mts.MintosProduct mp
inner join bi.MintosData md on md.lender_id = mp.ProductId 
where 1=1
    and mp.Status = 2
group by md.status
;
