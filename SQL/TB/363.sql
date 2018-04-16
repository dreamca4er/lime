with a as 
(
    select
        sl.id as StatusLogId
        ,a.RegionId
        ,left(cc.NumberMasked, 6) as Pan
        ,sl.ProductId
        ,sl.Status
        ,sl.StartedOn
        ,lead(sl.StartedOn) over (partition by sl.ProductId order by sl.StartedOn) as NextStatusStartedOn
        ,datediff(d, sl.StartedOn, isnull(lead(sl.StartedOn) over (partition by sl.ProductId order by sl.StartedOn), getdate())) + 1 as StatusTime
    from prd.vw_statusLog sl
    inner join prd.vw_Product p on p.productid = sl.ProductId
    inner join Client.Address a on a.ClientId = p.ClientId
    left join pmt.Payment pay on pay.ContractNumber = p.ContractNumber
        and pay.PaymentDirection = 1
        and pay.PaymentStatus = 5
        and pay.PaymentWay = 1
    left join pmt.CreditCardPaymentInfo ccpi on ccpi.PaymentId = pay.Id
    left join client.CreditCard cc on cc.Id = ccpi.CreditCardId
    where a.AddressType = 1
        and p.StartedOn >= '20180101'
        and p.status > 2
        and p.PaymentWay = 1
        and a.RegionId is not null
)

,Region as 
(
    select
        cast(RegionId as int) as RegionId
        ,count(HasOverdue) * 100.0 / count(*) as Perc
    from 
    (
        select 
            RegionId
            ,sum(distinct case when Status = 4 then 1 end) as HasOverdue
        from a
        group by RegionId, ProductId
    ) b
    group by cast(RegionId as int)
)

select *
from Region
/
select
   Pan
    ,count(HasOverdue) * 100.0 / count(*) as Perc
from 
(
    select 
        Pan
        ,sum(distinct case when Status = 4 then 1 end) as HasOverdue
    from a
    where Pan is not null
    group by Pan, ProductId
) b
group by Pan