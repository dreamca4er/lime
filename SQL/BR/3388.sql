with cr as 
(
    select
        crr.id as CreditRobotResultid
        ,crr.ClientId
        ,crr.CreatedOn 
        ,cast(crr.CreatedOn as date) as PeriodStart
        ,'20180627' as PeriodStartEnd
    from cr.CreditRobotResult crr
    where crr.reason like N'%Отсутствуют кредиты по информации от Эквифакс%'
        and crr.AnalysisResult = 3
        and cast(crr.CreatedOn as date) between '20180501' and '20180620'
    
    union all
    
    select
        crr.id as CreditRobotResultid
        ,crr.ClientId
        ,crr.CreatedOn 
        ,cast(crr.CreatedOn as date) as PeriodStart
        ,'20180907' as PeriodStartEnd
    from cr.CreditRobotResult crr
    where crr.reason like N'%Отсутствуют кредиты по информации от Эквифакс%'
        and crr.AnalysisResult = 3
        and cast(crr.CreatedOn as date) between '20180712' and '20180831'
)

,p as 
(
    select
        cr.*
        ,c.SubstatusName
        ,p.Productid
        ,p.StartedOn
        ,p.Amount
        ,p.StatusName
        ,p.PaymentWayName
    from cr
    inner join client.vw_client c on c.clientid = cr.clientid
    left join prd.vw_product p on cr.ClientId = p.ClientId
        and p.status > 2
        and cast(p.StartedOn as date) between cr.PeriodStart and cr.PeriodStartEnd
        and not exists 
            (
                select 1 from cr cr2
                where cr2.ClientId = cr.ClientId
                    and cr2.CreatedOn > cr.CreatedOn
                    and cast(p.StartedOn as date) between cr2.PeriodStart and cr2.PeriodStartEnd
            )
)

select *
from p
outer apply
(
    select top 1
        cb.TotalAmount
        ,cb.TotalPercent
        ,cb.Commission
        ,cb.Fine
    from bi.CreditBalance cb
    where cb.ProductId = p.ProductId
        and cb.InfoType = 'debt'
    order by cb.DateOperation desc
) cb

