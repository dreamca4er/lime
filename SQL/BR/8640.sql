select
    p.Productid
    , cs.name as CreditStatusName
    , p.StartedOn
    , dateadd(d, p.Period, p.StartedOn) as ContractPayDay 
    , cast(p.DatePaid as date) as RealDatePaid
    , pay.id as PaymentId
    , cast(pay.ProcessedOn as date) as PaymentDate 
    , pay.Amount as PaymentAmount
    , pw.Name as MoneyWay
    , pd.MintosPublishDate
    , mm.MintosPublicId
    , ps.Name as MintosStatus
    , iif(pdl.MintosStatusDate < mp.ModifiedOn, mp.ModifiedOn, pdl.MintosStatusDate) as MintosStatusDate
from [mts].[MintosProduct] mp
left join mts.EnumMintosProductState ps on ps.Id = mp.Status
outer apply
(
    select top 1 
        mpsl.StartedOn as MintosPublishDate
    from mts.MintosProductStatusLog mpsl
    where mpsl.ProductId = mp.id
        and mpsl.Status = 2
    order by mpsl.StartedOn desc
) pd
outer apply
(
    select top 1 
        mpsl.StartedOn as MintosStatusDate
    from mts.MintosProductStatusLog mpsl
    where mpsl.ProductId = mp.id
    order by mpsl.StartedOn desc
) pdl
outer apply
(
    select top 1 json_value(Content, '$.data.loan.public_id') as MintosPublicId
    from mts.MintosMessage mm
    where mm.productid = mp.id 
        and mm.type = 2
    order by mm.CreatedOn 
) mm
left join prd.vw_product p on mp.ProductId = p.Productid
left join prd.EnumProductState cs on cs.EnumId = p.Status
    and cs.ProductType = p.ProductType
left join pmt.Payment pay on pay.ContractNumber = p.ContractNumber
    and pay.PaymentStatus = 5
    and pay.PaymentDirection = 2
left join pmt.EnumPaymentWay pw on pw.id = pay.PaymentWay
where cast(mp.CreatedOn as date) >= '20190225'
order by p.Productid, pay.CreatedOn