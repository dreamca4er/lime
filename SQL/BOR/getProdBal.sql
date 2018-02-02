
CREATE FUNCTION [Acc].[getProdBal](@dateFrom nvarchar(30), @dateTo nvarchar(30)) 
RETURNS TABLE 
AS 

return
(

with b as 
(
    select
        po.ProductId
        ,cast(cast(r.Date as date) as datetime) as Date
        ,ac.Number as accNumber
        ,ac.BalAccountId
        ,r.SumKtNt - r.SumDtNt as opSum
        ,r.SumKtNt
        ,po.OperationTemplateId
    from acc.Record r
    inner join acc.Document d on d.Id = r.DocumentId
    inner join acc.ProductOperation po on po.Id = d.ProductOperationId
    inner join acc.Account ac on ac.id = r.AccountId
    where (try_cast(@dateTo as date) is not null or @dateTo is null)
        and (cast(r.Date as date) <= cast(@dateTo as date) or @dateTo is null)
        or try_cast(@dateTo as int) = 0
)

,gr as 
(
    select
        ProductId
        ,date
        ,isnull(sum(case when BalAccountId = 34 then opSum end), 0) as debtAmnt
        ,isnull(sum(case when BalAccountId = 34 and accNumber like '%1' then opSum end), 0) as debtAmntCurrAndRestr
        ,isnull(sum(case when BalAccountId = 34 and accNumber like '%2' then opSum end), 0) as debtAmntOver
        ,isnull(sum(case when BalAccountId = 35 then opSum end), 0) as debtPerc
        ,isnull(sum(case when BalAccountId = 35 and accNumber like '%1' then opSum end), 0) as debtPercCurrAndRestr
        ,isnull(sum(case when BalAccountId = 35 and accNumber like '%2' then opSum end), 0) as debtPercOver
        ,isnull(sum(case when BalAccountId = 36 and accNumber like '%4' then opSum end), 0) as debtComission
        ,isnull(sum(case when BalAccountId = 129 then opSum end), 0) as debtFine
        ,isnull(sum(case when BalAccountId = 115 then opSum end), 0) as overPay
        ,isnull(sum(case when BalAccountId = 43 then opSum end), 0) as reserve
        ,isnull(sum(case when BalAccountId = 34 and OperationTemplateId in (44, 54, 47, 57) then SumKtNt end), 0) as paidAmnt
        ,isnull(sum(case when BalAccountId = 35 and OperationTemplateId in (44, 54, 47, 57) then SumKtNt end), 0) as paidPerc
        ,isnull(sum(case when BalAccountId = 36 and accNumber like '%1' and OperationTemplateId in (44, 54, 47, 57) then SumKtNt end), 0) as paidProlong
        ,isnull(sum(case when BalAccountId = 36 and accNumber like '%4' and OperationTemplateId in (44, 54, 47, 57) then SumKtNt end), 0) as paidComission
        ,isnull(sum(case when BalAccountId = 129 and OperationTemplateId in (44, 54, 47, 57) then SumKtNt end), 0) as paidFine
        ,isnull(sum(case when BalAccountId = 115 and OperationTemplateId in (44, 54, 47, 57) then SumKtNt end), 0) as paidOverPay
        ,isnull(sum(case when BalAccountId = 2 and accNumber like '%' + cast(ProductId as nvarchar(10)) then opSum end), 0) as notDistributed
    from b
    where BalAccountId in (2, 43, 34, 35, 36, 129, 115)
    group by ProductId, date
)

,rv as 
(
    select
        ProductId
        ,date
        ,sum(debtAmnt) over (partition by ProductId order by date rows unbounded preceding) as debtAmnt
        ,sum(debtAmntCurrAndRestr) over (partition by ProductId order by date rows unbounded preceding) as debtAmntCurrAndRestr
        ,sum(debtAmntOver) over (partition by ProductId order by date rows unbounded preceding) as debtAmntOver
        ,sum(debtPerc) over (partition by ProductId order by date rows unbounded preceding) as debtPerc
        ,sum(debtPercCurrAndRestr) over (partition by ProductId order by date rows unbounded preceding) as debtPercCurrAndRestr
        ,sum(debtPercOver) over (partition by ProductId order by date rows unbounded preceding) as debtPercOver
        ,sum(debtComission) over (partition by ProductId order by date rows unbounded preceding) as debtComission
        ,sum(debtFine) over (partition by ProductId order by date rows unbounded preceding) as debtFine
        ,sum(overPay) over (partition by ProductId order by date rows unbounded preceding) as overPay
        ,sum(reserve) over (partition by ProductId order by date rows unbounded preceding) as reserve
        ,paidAmnt
        ,paidPerc
        ,paidProlong
        ,paidComission
        ,paidFine
        ,paidAmnt
        + paidPerc
        + paidProlong
        + paidComission
        + paidFine as paidTotal
        ,notDistributed
        ,sum(paidAmnt 
            + paidPerc 
            + paidProlong 
            + paidComission 
            + paidFine) over (partition by ProductId order by date rows unbounded preceding) as paidToDate
    from gr
)

    select *
    from rv
    where (try_cast(@dateFrom as date) is not null or @dateFrom is null)
        and (date >= cast(@dateFrom as date) or @dateFrom is null)
        or try_cast(@dateFrom as int) = 0
)
;
GO

select *
from [Acc].[getProdBal](@dateFrom nvarchar(30), @dateTo nvarchar(30))
