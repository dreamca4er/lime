/*
with oldpay as
(
    select isnull(p.ProcessedOn, p.CreatedOn) as OperationDate
        , p.Id as PaymentId
        , p.Amount
        , formatmessage(
                '{"ProductId":%i,"ProductType":%i,"PaymentId":%i,"Amount":%s,"Currency":"810","ContractNumber":"%s","PaymentWay":%i,"ReceivedOn":"%s","OperationDate":"%s"}'
                , p.ProductId
                , p.ProductType
                , p.Id
                , cast(p.Amount as nvarchar(40))
                , p.ContractNumber
                , p.PaymentWay
                , convert(nvarchar(23),isnull(p.ProcessedOn, p.CreatedOn), 126)
                , convert(nvarchar(23),isnull(p.ProcessedOn, p.CreatedOn), 126)
             )  as CommandSnapshot
        , p.Productid
        , 'Prd.Domain.Operations.ShortTermOperations.ShortTermCreditReceiveMoneyOperation' as OperationFullname
    from (
        select p.Id
            , cp.CreditId as ProductId
            , cp.DateCreated as ProcessedOn
            , p.DateCreated as CreatedOn
            , choose (p.Way, 5,2,1,4,3,0,6,7) as PaymentWay
            , iif(c.TariffId = 4, 2, 1) as ProductType
            , right( '0000000' + c.dogovornumber, 10) as ContractNumber
            , p.Amount, p.way
        from "BOR-DB-LIME-2".limezaim_website.dbo.Payments p
        inner join "BOR-DB-LIME-2".limezaim_website.dbo.CreditPayments cp on cp.PaymentId = p.Id
        inner join "BOR-DB-LIME-2".limezaim_website.dbo.Credits c on c.id = cp.CreditID
        where cp.CreditId = @productid
            and exists (select 1 from bi.ProjectConfig pc where pc.ProjectID = 0)
    ) p
)
*/

with oldpay as
(
    select top 0
        null as OperationDate
        , null as PaymentId
        , null as Amount
        , null as CommandSnapshot
        , null as Productid
        , null as OperationFullname
)
select
    'Prd.Domain.Commands.MoneyReceivedCommand, Prd.Domain, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null' as CommandType
    , 'Prd.Domain.Operations.ShortTermOperations.ShortTermCreditReceiveMoneyOperation' as OperationFullName
    , pm.CommandSnapshot
from (
    select isnull(pm.ProcessedOn, pm.CreatedOn) as OperationDate
        , pm.Id as PaymentId
        , pm.Amount
        , formatmessage(
                '{"ProductId":%i,"ProductType":%i,"PaymentId":%i,"Amount":%s,"Currency":"810","ContractNumber":"%s","PaymentWay":%i,"ReceivedOn":"%s","OperationDate":"%s"}'
                , p.ProductId
                , p.ProductType
                , pm.Id
                , cast(pm.Amount as nvarchar(40))
                , pm.ContractNumber
                , pm.PaymentWay
                , convert(nvarchar(23),isnull(pm.ProcessedOn, pm.CreatedOn), 126)
                , convert(nvarchar(23),isnull(pm.ProcessedOn, pm.CreatedOn), 126)
             )  as CommandSnapshot
        , p.Productid
        , 'Prd.Domain.Operations.ShortTermOperations.ShortTermCreditReceiveMoneyOperation' as OperationFullname
    from pmt.vw_Payment pm
    inner join prd.vw_product p on p.ContractNumber = pm.ContractNumber
        and pm.PaymentDirection = 2
    where 1=1
        and p.Productid = @productid
        and p.ProductType = 1
        and pm.PaymentStatus = 5
    union all
    select *
    from oldpay o
    where not exists (select 1 from Pmt.Payment pp where pp.id = o.PaymentId)
) pm

union all

select
    'Prd.Domain.Commands.ProlongCommand, Prd.Domain, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null'
    , 'Prd.Domain.Operations.ShortTermOperations.Prolong.ShortTermCreditProlong201810Operation' as OperationFullName
    , sp.CommandSnapshot
from (
    select sp.BuiltOn 
        , sp.Amount
        , sp.Startedon
        , sp.Period
        , formatmessage(
                    '{"ProductId":%i,"ProductType":1,"StartedOn":"%s","Amount":0.0,"Price":0.0,"Period":%i,"Rate":1.5,"OperationDate":"%s"}'
                    , sp.ProductId
                    , convert(nvarchar(23),sp.StartedOn, 126)
                    , sp.Period
                    , format(sp.BuiltOn, 'yyyy-MM-ddT00:00:00')
                    ) as CommandSnapshot 
        , sp.ProductId
    from prd.ShortTermProlongation sp
    where sp.ProductId = @productid 
) sp
order by 1, CommandSnapshot