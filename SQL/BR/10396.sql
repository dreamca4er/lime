with i as
(
    select
        p.ProductId
        , p.ContractNumber
        , convert(date, v.CloseDate, 104) as CloseDate
        , p.StatusName
        , p.CanceledByName
        , sl.*
    -- update ip set status = 1, CanceledBy = 0
    from
    (
        values
        ('LM70154-6501460', '09.05.2019', '10.06.2019')
        , ('LM70154-6503153', '16.05.2019', '31.05.2019')
    ) v(ContractNumber, StartedOn, CloseDate)
    inner join prd.vw_Insurance p on p.contractnumber = v.contractnumber
    inner join prd.InsurancePolicy ip on ip.id = p.productid
    outer apply
    (
        select max(StartedOn) as CancelDate
        from prd.InsurancePolicyStatusLog sl
        where sl.productid = p.productid
            and sl.Status = 1
    ) sl
)
/*
insert prd.InsurancePolicyStatusLog
(
    StartedOn,Status,ProductId,CreatedOn,CreatedBy
)
select
    i.CloseDate as StartedOn
    , 1 as Status
    , i.ProductId
    , getdate() as CreatedOn
    , 0x44 as CreatedBy
from i
where not exists
    (
        select *--1
        from prd.InsurancePolicyStatusLog sl
        where sl.ProductId = i.ProductId
            and sl.Status = 1
    )
*/
/*
insert prd.OperationLog
(
    OperationDate,CommandType,CommandSnapshot,ProductId,Suspended,OperationFullName
)
select
    getdate() as OperationDate
    , 'Prd.Domain.Commands.CancelCommand, Prd.Domain, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null' as CommandType
    , (
        select 
            ProductId
            , 3 as ProductType
            , CloseDate as CanceledOn
            , cast(0 as bit) as NotCloseAccounts
        for json path, without_array_wrapper
    ) as CommandSnapshot
    , i.ProductId
    , 0 as Suspended
    , 'Prd.Domain.Operations.InsurancePolicyOperations.InsurancePolicyCancelOperation' as OperationFullName
from i
where not exists
    (
        select 1 from prd.OperationLog ol
        where ol.CommandType = 'Prd.Domain.Commands.CancelCommand, Prd.Domain, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null'
            and ol.ProductId = i.ProductId
    )
*/