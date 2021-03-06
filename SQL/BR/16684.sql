with p as 
(
    select --top 50 
        cast(p.ProductId as nvarchar(20)) as ProductId
        , p.StartedOn
        , p.StatusName
        , p.ClientId
    from stage.dbo.br16684 br
    left join borneo.prd.vw_product p on p.ContractNumber = br.Номер_договора
    where not exists
        (
            select 1 from borneo.pmt.vw_Payment p 
            where p.ContractNumber = br.Номер_договора
                and p.PaymentDirection = 2
                and p.CreatedOn >= '20191130'
        )
        and p.Status != 8
)

--select top 100 * from p order by cast(ProductId as int) /*
select stuff
(
    (
        select top 100 ',' + ProductId as 'text()' 
        from p
--        where p.ProductId != 146469
        order by cast(ProductId as int) for xml path('')
    )
, 1, 1, '')
--*/
/

--insert lgl.WriteOffDebt(Date,CreatedOn,Description,CreatedBy,CreditorId)
select 
    '2019-11-30' as Date
     , '20191226 12:00' as CreatedOn
     , N'Приказ на списание безнадежной задолженности' as Description
     , 0x44 as CreatedBy
     , 1 as CreditorId
/

with d as 
(
    select
        N'банкрот' as Reason
        , c.clientid
        , c.fio
        , p.ProductId
        , p.ContractNumber
        , cast(p.CreatedOn as date) as ContractDate
        , cast(p.StartedOn as date) as StartedOn
        , p.Amount
        , p.Period
        , os.OverdueStartedOn
        , wo.*
    from stage.dbo.br16684 b
    inner join prd.vw_Product p on p.ContractNumber = b.Номер_договора
    inner join client.vw_client c on c.clientid = p.ClientId
    outer apply
    (
        select top 1 cast(sl.StartedOn as date) as OverdueStartedOn
        from prd.vw_statusLog sl
        where sl.ProductId = p.Productid
            and sl.Status = 4
        order by id desc
    ) os
    outer apply
    (
        select
            sum(iif(sj.SumType / 1000 = 1, RawSum, 0)) as AmountWrittenOff
            , sum(iif(sj.SumType / 1000 = 2, RawSum, 0)) as PercentWrittenOff
            , sum(iif(sj.SumType = 4011, RawSum, 0)) as CommissionWrittenOff
            , sum(iif(sj.SumType = 3021, RawSum, 0)) as PenaltyWrittenOff
        from acc.ProductSumJournal sj
        where sj.ProductId = p.Productid
            and sj.ProductType = p.ProductType
            and sj.ChangeType = 10
    ) wo
    where p.Status = 8
)
select *
from d
/
--insert lgl.WriteOffDebtProduct (ProductId,WriteOffReason,WriteOffDebtId,CreatedOn,CreatedBy) 
select
    ProductId
    , 1 as WriteOffReason
    , 1 as WriteOffDebtId
    , '20191226' as CreatedOn
    , 0x44 as CreatedBy
from d