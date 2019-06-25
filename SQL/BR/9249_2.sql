select 
    c.*
    , isnull(p.ContractPayDay, stp.ProlongEnd) as PayDay
from dbo.br9310_check c
left join mts.vw_MintosProduct mp on mp.MintosId = c.id
left join prd.vw_product p on p.Productid = mp.ProductId
outer apply
(
    select top 1
        dateadd(d, stp.Period - 1, stp.StartedOn) as ProlongEnd
    from prd.ShortTermProlongation stp
    where stp.ProductId = mp.ProductId
        and stp.IsActive = 1 
    order by stp.StartedOn desc 
) stp
where c.id not in
    (
        select Mintos_Loan_ID
        from dbo.br9204_pending
    )
    and isnull(p.ContractPayDay, stp.ProlongEnd) >= '20190603'
    