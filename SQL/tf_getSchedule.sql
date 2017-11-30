CREATE FUNCTION [dbo].[tf_getSchedule](@cred int)
RETURNS TABLE 
AS 

return
(
with c as 
(
    select
        c.DateStarted
        ,Amount
        ,"Percent"
        ,Period
        ,"Percent" * 14.0 / 100 as k
        ,Period / 14 as cntPay
    from dbo.Credits c
    where c.id = @cred
)

,preCalc as 
(
    select
        *
        ,round((k + k / (power(1 + k, cntPay) - 1)) * amount, 2) as fullPayment
        ,round(c.Amount * c."Percent" / 100, 2) * 14 as percentAmount
    from c
)

,cte (Date, amnt, pct, Total, Residue, toPay, paymentNum) as
(
select 
    dateadd(d, 14, DateStarted) as Date
    ,cast(fullPayment - percentAmount as numeric(10, 2))as amnt
    ,cast(percentAmount as numeric(10, 2)) as pct
    ,fullPayment as Total
    ,cast(amount as numeric(10, 2)) as Residue
    ,amount - (fullPayment - percentAmount) as toPay 
    ,1 as paymentNum
from preCalc c

union all

select
    dateadd(d, 14 * (paymentNum + 1), DateStarted)
    ,cast(case 
        when paymentNum = cntPay - 1 then toPay
        else Total - round(toPay * c."Percent" / 100, 2) * 14
    end as numeric(10, 2))
    ,cast(round(toPay * c."Percent" / 100, 2) * 14 as numeric(10, 2))
    ,case 
        when paymentNum != cntPay - 1 then Total
        else toPay + cast(round(toPay * c."Percent" / 100, 2) * 14 as numeric(10, 2))
    end
    ,cast(toPay as numeric(10, 2))
    ,case 
        when paymentNum != cntPay - 1 
        then toPay - (Total - cast(round(toPay * c."Percent" / 100, 2) * 14 as numeric(10, 2)))
        else 0
    end
    ,paymentNum + 1
from cte
inner join preCalc c on 1 = 1
where paymentNum < cntPay
)

    select
        "Date"
        ,amnt as Amount
        ,pct as "Percent"
        ,Residue
        ,Total
    from cte
);

GO
