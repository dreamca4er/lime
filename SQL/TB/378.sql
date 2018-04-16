select
    sum(Amount) as TotalAmount
    ,sum(var1) as var1
    ,sum(var2) as var2
from 
(
    select
        Amount
        ,Amount * 0.005 + 20 as var1
        ,(select max(v) from (values(Amount * 0.005), (30)) as t(v)) as var2
    from prd.vw_Product
    where StartedOn >= '20180101'
        and PaymentWay = 1
        and status > 2
) a