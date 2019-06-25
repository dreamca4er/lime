with sp as 
(
    select
        mp.MintosId
        , mp.ProductId
        , mm.CreatedOn as MessageSentOn
        , oj.SuccessfulySentPayment
        , oj.ResponseKey
        , oj.ResponseValue
        , iif(mm.Action = 3, 'Payment', 'Early repayment') as InfoType
    from mts.MintosMessage mm
    inner join mts.MintosProduct mp on mp.Id = mm.ProductId
    outer apply
    (
        select
            oj."key" as ResponseKey
            , oj.value as ResponseValue
            , case when value = '{}' then 1 end as SuccessfulySentPayment
        from openjson(mm.Content) oj
        where oj."key" = 'data'
    ) oj
    where mm.Action in (3, 4) -- Отправка платежа в минтос
        and mm.Type = 2
)


,pending as (
    select
        mp.Id as MintosProductId
        , m.*
        , ps.PublishDate
        , isnull(sp.InfoType, er.InfoType) as InfoType
        , isnull(sp.MessageSentOn, er.MessageSentOn) as SuccessfulySentDate
        , pr.Productid
        , dateadd(d, pr.Period, pr.StartedOn) as PayDay
        , pr.DatePaid
        , stp.FirstProlongStarted
        , pay.*
    from dbo.br9204_pending m --br9204_pending m --
    left join mts.MintosProduct mp on mp.ProductId = m.Lender_Loan__ID
    left join prd.vw_product pr on pr.Productid = mp.ProductId
    outer apply
    (
        select min(sl.StartedOn) as PublishDate
        from mts.MintosProductStatusLog sl
        where sl.ProductId = mp.Id
            and sl.Status = 2 -- Опубликован
    ) ps
    outer apply
    (
        select 
            max(pay.CreatedOn) as LastPaymentDate
            , count(*) as PaymentCount
        from pmt.Payment pay
        where pay.ContractNumber = pr.ContractNumber
            and pay.PaymentDirection = 2
            and pay.PaymentStatus = 5
    ) pay
    outer apply
    (
        select min(sl.StartedOn) as PublishDate
        from mts.MintosProductStatusLog sl
        where sl.ProductId = mp.Id
            and sl.Status = 2 -- Опубликован
    ) p
    outer apply
    (
        select min(stp.StartedOn) as FirstProlongStarted
        from prd.ShortTermProlongation stp
        where stp.ProductId = pr.Productid
            and stp.IsActive = 1 
    ) stp
    left join sp on sp.ProductId = mp.ProductId
        and sp.SuccessfulySentPayment = 1
        and sp.InfoType = 'Payment'
    left join sp er on er.ProductId = mp.ProductId
        and er.SuccessfulySentPayment = 1
        and er.InfoType = 'Early repayment'
)

,pubid as 
(
    select
        mp.ProductId
        , mp.Id as MintosProductId
        , pub.public_id
        , mps.Description as MintosProductStatus
        , ps.PublishDate
    from mts.MintosProduct mp
    inner join mts.EnumMintosProductState mps on mps.Id = mp.Status
    cross apply 
    (
        select top 1 json_value(Content, '$.data.loan.public_id') as public_id
        from mts.MintosMessage mm
        where mm.ProductId = mp.Id
            and mm.Action = 2
            and mm.type = 2
    ) pub
    outer apply
    (
        select min(sl.StartedOn) as PublishDate
        from mts.MintosProductStatusLog sl
        where sl.ProductId = mp.Id
            and sl.Status = 2 -- Опубликован
    ) ps
)

--/
--drop table if exists #mp
--;
--
--select *
--into #mp
--from mts.vw_MintosProduct mp
--/

select
    c.*
    , mp.ProductStatus
    , mp.MintosProductStatus
    , mp.PublishDate
    , datediff(d, mp.PublishDate, '20190603')
from dbo.br9204_check c
left join #mp mp on mp.public_id = c.Mintos_Loan_ID
where c.Loan_originator_ID not in (select Productid from pending)
    and c.Loan_Status = 'active'
    and (datediff(d, mp.PublishDate, '20190610') >= 60 or mp.ProductStatus = 7)
    
    
select 