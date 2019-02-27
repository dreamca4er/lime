declare
    @DateFrom date = '20190131'
    , @DateTo date = cast(getdate() as date)
;

drop table if exists #cpd
;

with s as 
(
    select id as Tech
    from sts.users
    where UserName = 'FakeCollectorTechnical'
)
select
    cpd.ProductId
    , cpd.ClientId
    , cpd.OverdueAmountDebt as OverdueAmount
    , cpd.OverduePercentDebt as OverduePercent
    , cpd.FineDebt as PenaltyDebt
    , cpd.CommissionDebt as LoanComissionDebt
    , cpd.Date as DateNow
into #cpd
from s, bi.CollectorPortfolioDetail cpd
where cpd.Date between @DateFrom and  @DateTo
    and exists 
    (
        select 1 from bi.CollectorPortfolioDetail cpd2
        where cpd2.ProductId = cpd.ProductId
            and cpd2.Date = dateadd(d, -1, cpd.Date)
            and cpd2.CollectorId != cpd.CollectorId
            and cpd2.CollectorId = s.Tech
    )
;

with t as 
(
    select
        iif(uuid = 'E24DA8BA-06BB-2FF9-B3EB-C46706E108DD', 1, 2) as ProductType
        , uuid
        , Template
    from doc.CommunicationTemplate
    where Uuid in ('E24DA8BA-06BB-2FF9-B3EB-C46706E108DD', 'E78DA8BA-06BB-2FF9-B3EB-C46706E478DD')
)

,n as 
(
    select
        cpd.*
        , c.FirstName + isnull(' ' + c.FatherName, '') as "IO"
        , c.LastName + ' ' + c.FirstName + isnull(' ' + c.FatherName, '') as FIO
        , p.ContractNumber
        , p.StartedOn as ContractDate
        , t.Template
        , t.uuid
        , isnull(stp.ProlongEnd, dateadd(d, p.Period, p.StartedOn)) as DatePay
    from #cpd cpd
    inner join client.Client c on c.id = cpd.ClientId
    inner join prd.vw_Product p on p.productid = cpd.ProductId
    inner join t on t.ProductType = p.ProductType 
    outer apply
    (
        select top 1 
            dateadd(d, stp.Period - 1, stp.StartedOn) as ProlongEnd
        from prd.ShortTermProlongation stp
        where stp.ProductId = cpd.ProductId
            and stp.IsActive = 1
            and stp.StartedOn < cpd.DateNow
        order by stp.StartedOn desc
    ) stp
    where not exists
        (
            select 1 from ecc.Notice n
            where n.ClientId = c.id
                and n.TemplateUuid = t.uuid
                and cast(n.CreatedOn as date) = cpd.DateNow
        )
)

insert ecc.Notice
(
    ClientId,ProductId,Text,CreatedOn,CreatedBy,TemplateUuid,NoticeType,NoticeShowType
)
select
    n.ClientId
    , n.ProductId
    , replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(Template
                , '{{IO}}', "IO") 
                , '{{ContractNumber}}', ContractNumber)
                , '{{ContractDate}}', format(ContractDate, 'dd/MM/yyyy'))
                , '{{DateNow}}', format(DateNow, 'dd/MM/yyyy'))
                , '{{OverdueAmount}}', OverdueAmount)
                , '{{OverduePercent}}', OverduePercent)
                , '{{PenaltyDebt}}', PenaltyDebt)
                , '{{LoanComissionDebt}}', LoanComissionDebt)
                , '{{DatePay}}', format(DatePay, 'dd/MM/yyyy'))
                , '{{Fio}}', Fio)
    as "Text"
    , DateNow as CreatedOn
    , 0x44 as CreatedBy
    , uuid as TemplateUuid
    , 2 as NoticeType
    , 1 as NoticeShowType
from n