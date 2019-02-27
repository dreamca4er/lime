/*
select
    op.ProductId
into dbo.br5145
from Collector.OverdueProduct op
inner join prd.Product pr on pr.id = op.ProductId
inner join prd.ShortTermCredit p on p.id = op.ProductId
    and p.Status = 4
outer apply
(
    select top 1 
        cb.TotalPercent * -1 as PercentDebt
        , cb.TotalAmount * -1 as AmountDebt
    from bi.CreditBalance cb
    where cb.ProductId = op.ProductId
        and cb.InfoType = 'debt'
    order by cb.DateOperation desc
) debt
outer apply
(
    select
        sum(cb.TotalPercent) as PercentPaid
    from bi.CreditBalance cb
    where cb.ProductId = op.ProductId
        and cb.InfoType = 'payment'
) paid
where op.IsDone = 0
    and op.GroupId = 6
    and OverdueDays >= 180
    and (debt.PercentDebt >= debt.AmountDebt * 2 
        or debt.PercentDebt + paid.PercentPaid >= pr.Amount * 3) 
*/

select *
from dbo.br5145
/

select top 10 *
-- update p set IsPaused = 1
from prd.Product p
inner join dbo.br5145 l on l.ProductId = p.Id 

-- insert into prd.ProductIsPausedLog (StartedOn,CreatedOn,CreatedBy,IsPaused,ProductId)
select
    getdate() as StartedOn
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
    , 1 as IsPaused
    , ProductId
from dbo.br5145

-- insert prd.OperationLog (OperationDate,CommandType,CommandSnapshot,ProductId,OperationFullName)
select
    getdate() as OperationDate
    , 'Prd.Domain.Commands.PausedProductCommand, Prd.Domain, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null' as CommandType
    , (
        select 
            Productid
            , getdate() as OperationDate
            , getdate() as StartedOn
        from (select 1 as a) b 
        for json auto, without_array_wrapper
    ) as CommandType
    , ProductId
    , 'Prd.Domain.Operations.CommonOperations.ProductPausedOperation' as OperationFullName 
from dbo.br5145

