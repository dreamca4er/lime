ALTER VIEW [Prd].[vw_product] as 
select
    prod.id as productid
    ,prod.CreatedOn
    ,prod.StartedOn
    ,prod.ContractNumber
    ,epw.Description as PaymentWayName
    ,case when stc.Id is not null then 1 else 2 end as productType
    ,prodSnap.Name + '\' + prodSnap.GroupName as tariffName
    ,prodSnap.PercentPerDay
    ,isnull(sps.Description, lps.Description) as statusName
    ,isnull(stc.Period, ltc.Period) as Period
    ,prod.Amount
    ,prodSnap.Psk
    ,isnull(stsl.StartedOn, ltsl.StartedOn) as datePaid
    ,prodSnap.PrivilegeFactor
    ,prodSnap.PenaltyAmount
    ,prodSnap.PenaltyPercent
    ,prodSnap.CanProlong
    ,isnull(stc.Status, ltc.Status) as status
    ,pay.PaymentWay
from prd.Product prod
left join prd.ShortTermCredit stc on stc.Id = prod.id
left join prd.LongTermCredit ltc on ltc.Id = prod.id
left join prd.EnumProductState sps on sps.EnumId = stc.Status
    and sps.ProductType = 1
left join prd.EnumProductState lps on lps.EnumId = ltc.Status
    and lps.ProductType = 2
left join pmt.Payment pay on pay.ContractIdentifier = prod.ContractNumber
    and pay.PaymentDirection = 1
left join pmt.EnumPaymentWay epw on epw.Id = pay.PaymentWay
left join prd.ShortTermStatusLog stsl on stsl.Product_Id = prod.Id
    and stsl.Status = 5
left join prd.LongTermStatusLog ltsl on ltsl.Product_Id = prod.id
    and ltsl.Status = 5
outer apply 
(
    select top 1 *
    from openjson(prod.ConditionSnapshot)
        with (
                StartedOn datetime '$.StartedOn'
                ,PercentPerDay numeric(5,2) '$.PercentPerDay'
                ,Psk numeric (7, 3) '$.Psk'
                ,Name nvarchar(20) '$.Name'
                ,GroupName nvarchar(20) '$.GroupName'
                ,PrivilegeFactor numeric(5, 2) '$.PrivilegeFactor'
                ,PenaltyAmount numeric(18, 2) '$.PenaltyAmount'
                ,PenaltyPercent numeric(5, 2) '$.PenaltyPercent'
                ,CanProlong nvarchar(5) '$.CanProlong'
        ) prodSnap
    order by StartedOn
) prodSnap

GO

select *
from [Prd].[vw_product]