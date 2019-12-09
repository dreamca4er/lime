/*
declare
    @Workers int = 1
    , @PackSize int = 100
    , @CheckSuspended bit = 1
    , @CurrentDate date = cast(getdate() as date)
;
*/

with mr as 
(
    select
        p.ProcessedOn as OperationDate
        , 'Prd.Domain.Commands.MoneyReceivedCommand, Prd.Domain, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null' as CommandType
        , j.CommandSnapshot
        , prod.Id as ProductId
        , 0 as Suspended
    from pmt.vw_Payment p
    inner join prd.Product prod on prod.ContractNumber = p.ContractNumber
    inner join stage.dbo.ProductsToCalc ptc on ptc.Productid = prod.Id
    outer apply
    (
        select
            prod.Id as ProductId
            , 2 as ProductType
            , p.Id as PaymentId
            , p.Amount
            , '810' as Currency
            , prod.ContractNumber
            , p.PaymentWay
            , p.ProcessedOn as ReceivedOn
            , p.ProcessedOn as OperationDate
        for json path, without_array_wrapper, include_null_values
    ) j(CommandSnapshot)
    where 1=1
--        and prod.id = 441724
        and p.PaymentDirection = 2
        and p.PaymentStatus = 5
)

,sched as 
(
    select
        ltsl.StartedOn as OperationDate
        , 'Prd.Domain.Commands.RepaymentCommand, Prd.Domain, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null' as CommandType
        , j.CommandSnapshot
        , lts.ProductId
        , 0 as Suspended
    from prd.LongTermSchedule lts
    inner join prd.LongTermScheduleLog ltsl on ltsl.ScheduleId = lts.Id
    inner join stage.dbo.ProductsToCalc ptc on ptc.Productid = lts.Productid
    outer apply
    (
        select
            lts.ProductId
            , 2 as ProductType
            , ltsl.StartedOn as OperationDate
        for json path, without_array_wrapper, include_null_values
    ) j(CommandSnapshot)
    where lts.SchType = 2
--        and lts.ProductId = 441724
)

,ms as
(
    select
        msent.MoneySent as OperationDate
        , N'Prd.Domain.Commands.MoneySentCommand, Prd.Domain, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null' as CommandType
        , j.CommandSnapshot
        , p.Productid
        , 0 as Suspended
    -- update pay set pay.ProcessedOn = pay.CreatedOn
    from prd.vw_Product p
    inner join pmt.Payment pay on pay.id = p.BorrowPaymentId
    inner join stage.dbo.ProductsToCalc ptc on ptc.Productid = p.Productid
    outer apply
    (
        select 
            cast(cast(cast(pay.ProcessedOn as date) as datetime) + '23:59:59' as datetime2) as MoneySent
    ) msent
    outer apply
    (
        select
            p.Productid
            , p.ContractNumber
            , p.ProductType
            , p.BorrowPaymentId as PaymentId
            , p.PaymentWay
            , pay.Amount
            , '810' as Currency
            , msent.MoneySent as SentOn
            , msent.MoneySent as OperationDate
            , cast(1 as bit) as IsSuccess
            , null as Reason
        for json path, without_array_wrapper, include_null_values
    ) j(CommandSnapshot)
--    where p.ProductId = 441724
)

/*
,MovedPaymnets as 
(
    select
        p.Amount
        , '810' as Currency
        , 5 as PaymentStatus
        , iif(Is3DSecure = 1, 3, 1) as PaymentType
        , isnull(p.OrderId, '') as "Order"
        , isnull(p.OrderDescription, '') as OrderDescription
        , right('000000' + c.DogovorNumber, 10) as ContractNumber
        , p.DateCreated as ProcessedOn
        , p.DateCreated as CreatedOn
        , 0x44 as CreatedBy
        , pwn.Id as PaymentWayId
    from "KONGA-DB".LimeZaim_Website.dbo.ProductsToCalc ptc
    inner join "KONGA-DB".LimeZaim_Website.dbo.CreditPayments cp on cp.CreditId = ptc.Productid 
    inner join "KONGA-DB".LimeZaim_Website.dbo.Payments p on p.Id = cp.PaymentId
    inner join "KONGA-DB".LimeZaim_Website.dbo.Credits c on c.Id = ptc.Productid
    outer apply
    (
        select
            case
                when p.way = 1 then 5
                when p.way = 2 then 2
                when p.way = 3 then 1
                when p.way = 4 then 4
                when p.way = 5 then 3
            end as PaymentWay
    ) pw
    left join pmt.PaymentWay pwn on pwn.PaymentWayType = pw.PaymentWay
        and pwn.Provider != 11
        and pwn.Direction = 2
    where p.Status = 3
        and not exists
        (
            select 1 from mr
            where mr.Id = p.Id
        )
        and not exists
        (
            select 1 from stage.dbo.PaymentsToMigrate pm
            where pm.ContractNumber = right('000000' + c.DogovorNumber, 10)
                and pm.CreatedOn = p.DateCreated
        )
        and p.Amount > 0
)
*/

/*,upd as 
(
    select count(*)
    --update p set p.ProcessedOn = p.CreatedOn
    from mr
    inner join pmt.Payment p on p.Id = mr.Id
    left join "KONGA-DB".LimeZaim_Website.dbo.Payments op on op.Id = p.Id
    where mr.OperationDate is null
)
*/
,un as 
(
    select * from ms
    
    union all 
    
    select * from mr
    
    union all
    
    select * from sched
)

--insert prd.OperationLog 
--(
--    OperationDate,CommandType,CommandSnapshot,Productid,Suspended,Number
--)
select *, row_number() over (partition by un.ProductId, un.OperationDate order by 1/0) as Number
--into stage.dbo.CommandsForProductsToCalc
from un
where not exists
    (
        select 1 from prd.OperationLog ol
        where ol.ProductId = un.ProductId
            and ol.CommandType = un.CommandType
            and ol.OperationDate = un.OperationDate
    )


/

--update ol set
--    ol.OperationDate = nd.NewDate
--    , ol.CommandSnapshot = json_modify(json_modify(ol.CommandSnapshot, '$.SentOn', nd.NewDate), '$.OperationDate', nd.NewDate)
select count(*)
from stage.dbo.ProductsToCalc ptc
inner join prd.OperationLog ol on ol.ProductId = ptc.Productid
    and CommandType = 'Prd.Domain.Commands.MoneySentCommand, Prd.Domain, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null' 
outer apply
(
    select top 1 *
    from prd.OperationLog ol
    where ol.ProductId = ptc.ProductId
    order by ol.OperationDate
) olf
outer apply
(
    select convert(nvarchar(30), dateadd(ss, -1, olf.OperationDate), 126) as NewDate
) nd
where olf.CommandType != 'Prd.Domain.Commands.MoneySentCommand, Prd.Domain, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null'
/

select *
from stage.dbo.CommandsForProductsToCalc


select
    ol.*
from stage.dbo.ProductsToCalc ptc
inner join prd.OperationLog ol on ol.ProductId = ptc.Productid