--select c.Mintos_Loan_ID, mp.ProductId
--into #br9310
--from dbo.br9310_check c
--left join mts.vw_MintosProduct mp on mp.MintosId = c.id

select
    c.*
--    , b.*
--    , p.Status
from #br9310 b
left join prd.vw_product p on p.ProductId = b.ProductId
left join dbo.br9310_check c on c.Mintos_Loan_ID = b.Mintos_Loan_ID
where p.Status not in (4, 5, 7)
    and dateadd(d, 60, p.StartedOn) > cast(getdate() as date)
/

select
    p.ClientId
    , p.Productid
    , p.ContractNumber
    , p.StartedOn
    , p.Period
    , dateadd(d, p.Period, p.StartedOn) as ContractPayDay
    , p.Amount
    , p.ProductTypeName
    , p.PercentPerDay
    , mp.MintosProductStatusName
from prd.vw_product p
outer apply
(
    select top 1
        mp.PublishDate
        , mp.MintosProductStatusName
    from mts.vw_MintosProduct mp
    where mp.ProductId = p.Productid
) mp
where p.Status = 3
    and p.StartedOn between '20190520' and '20190603'
    and p.ProductType = 1
    and mp.PublishDate is null
/

select
    c.*
--    , b.*
--    , p.Status
from #br9310 b
left join prd.vw_product p on p.ProductId = b.ProductId
left join dbo.br9310_check c on c.Mintos_Loan_ID = b.Mintos_Loan_ID
where p.Status = 7
    and
    (
        exists
        (
            select 1 from prd.ShortTermProlongation stp
            where stp.ProductId = p.Productid
                and stp.IsActive = 1
                and cast(stp.StartedOn as date) >= '20190527'
        )
        or
        exists
        (
            select 1 from prd.LongTermProlongation ltp
            where ltp.ProductId = p.Productid
                and ltp.IsActive = 1
                and cast(ltp.StartedOn as date) >= '20190527'
        )
    )
    and exists
    (
        select 1 from prd.vw_AllProducts ap
        where ap.ClientId = p.ClientId
            and ap.ProductId < p.Productid
    )
/

select
    p.ClientId
    , p.Productid
    , p.ContractNumber
    , p.StartedOn
    , p.Period
    , dateadd(d, p.Period, p.StartedOn) as ContractPayDay
    , p.Amount
    , mp.MintosProductStatusName
from prd.vw_product p
outer apply
(
    select top 1
        mp.PublishDate
        , mp.MintosProductStatusName
    from mts.vw_MintosProduct mp
    where mp.ProductId = p.Productid
) mp
where p.Status = 3
    and p.StartedOn between '20190520' and '20190603'
    and p.PrivilegeFactor = 0
    and mp.PublishDate is null
    and p.ProductType = 1