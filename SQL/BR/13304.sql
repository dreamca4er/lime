--alter table dbo.br13304 alter column Type nvarchar(100)
--;

drop table if exists #Discounts
;

select
    psc.BusinessDate
    , d.DateRegistered
    , psc.ProductId
    , p.ClientId
    , psc.Sum
    , psc.RawSum
    , psc.State
into #Discounts
from acc.ProductSumChange psc
inner join acc.Document d on d.id = psc.DocumentId
inner join acc.Account ad on ad.id = d.AccountDtId
inner join acc.Account ak on ak.id = d.AccountKtId
inner join prd.Product p on p.id = psc.ProductId
    and p.ProductType = psc.ProductType
where ad.Number like '71802%'
    and ak.Number like '48802%'
    and psc.ChangeType = 5
    and psc.State in (2, 4)
;

/
select *
from #Discounts d
inner join prd.vw_product p on p.Productid = d.ProductId
where 1=1
--    and cast(d.BusinessDate as date) != cast(d.DateRegistered as date)
    and p.Status = 1
    and exists
    (
        select 1 from ecc.Notice n
        where n.ClientId = p.ClientId
            and n.ProductId = p.Productid
            and n.TemplateUuid = '48B48662-4987-4158-87DE-17D43A70099A'
            
    )
/

select 
    d.BusinessDate
    , d.DateRegistered
    , d.ProductId
    , d.Sum
    , d.RawSum
    , d.State
    , c.clientid
    , c.fio
    , p.ContractNumber
    , p.CreatedOn
    , ld.LoginDate
    , cd.PropertyValue as CompanyDetails
    , N'Multiple Notices' as Type
    , n.Notices--n.*
into dbo.br13304
from doc.CompanyDetails cd, #Discounts d
inner join prd.vw_product p on p.Productid = d.ProductId
inner join client.vw_client c on c.clientid = p.ClientId
outer apply
(
    select min(cal.OperationDate) as LoginDate
    from client.ClientActionLog cal
    where cal.ClientId = p.ClientId
        and cal.OperationType = 1
        and cal.OperationDate > d.BusinessDate
) ld
outer apply
(
    select *
    from ecc.Notice n
    where n.ClientId = p.ClientId
        and n.ProductId = p.Productid
        and n.TemplateUuid = '48B48662-4987-4158-87DE-17D43A70099A'
    for json auto
) n(Notices)
where 1=1
    and exists
    (
        select 1 from ecc.Notice n2
        where n2.ClientId = p.ClientId
            and n2.ProductId = p.Productid
            and n2.TemplateUuid = '48B48662-4987-4158-87DE-17D43A70099A'
        group by n2.ProductId
        having count(*) > 1            
    )
    and cd.PropertyName = 'OrgTitleShort'
order by p.Productid

/

select n2.* -- delete n2
from ecc.Notice n2
inner join dbo.br13304 d on n2.ProductId = d.Productid
    and n2.TemplateUuid = '48B48662-4987-4158-87DE-17D43A70099A'
    and Type = N'Multiple Notices'
/
--insert ecc.Notice
--(
--    AvailableFrom,ClientId,CreatedBy,CreatedOn,ReadDate,NoticeShowType,NoticeType,ProductId,TemplateUuid,Text
--)
select
    b.BusinessDate as AvailableFrom
    , b.ClientId
    , 0x44 as CreatedBy
    , dateadd(hour, 1, b.BusinessDate) as CreatedOn
    , dateadd(minute, 1, b.LoginDate) as ReadDate
    , 1 as NoticeShowType
    , 3 as NoticeType
    , b.ProductId
    , d.Uuid as TemplateUuid
    , replace(replace(replace(replace(replace(replace(d.Template
            , '{{Fio}}', b.Fio)
            , '{{DateNow}}', format(b.BusinessDate, 'dd/MM/yyyy'))
            , '{{ContractNumber}}', b.ContractNumber)
            , '{{ContractDate}}', format(b.CreatedOn, 'dd/MM/yyyy'))
            , '{{DiscountAmount}}', b.RawSum)
            , '{{CreditorCompany}}', b.CompanyDetails) as Text
from doc.CommunicationTemplate d, dbo.br13304 b
where b.Type = N'Multiple Notices'
    and d.id = 1760
/

select 
    d.ProductId
    , n2.text as OldText
    , replace(n2.text, substring(n2.text, patindex(N'%Вам%был%', n2.text), 18), N'Вам ' + format(d.BusinessDate, N'dd/MM/yyyy') + N' был') as NewText
-- update n2 set n2.text = replace(n2.text, substring(n2.text, patindex(N'%Вам%был%', n2.text), 18), N'Вам ' + format(d.BusinessDate, N'dd/MM/yyyy') + N' был')
from #Discounts d
left join ecc.Notice n2 on n2.ClientId = d.ClientId
    and n2.ProductId = d.Productid
    and n2.TemplateUuid = '48B48662-4987-4158-87DE-17D43A70099A'
where 1=1
    and
    (
        exists
        (
            select 1 from prd.vw_product p
            where p.Productid = d.Productid
                and p.PrivilegeFactor = 1
        )
        or
        exists
        (
            select 1 from prd.vw_statusLog sl
            where sl.Productid = d.Productid
                and sl.Status = 4
        )
    )
    and exists
    (
        select 1 from ecc.Notice n
        where n.ClientId = d.ClientId
            and n.ProductId = d.Productid
            and n.TemplateUuid = '48B48662-4987-4158-87DE-17D43A70099A'    
    )
/
-- create index IX_client_ClientActionLog_ClientId_OperationDate on client.ClientActionLog(ClientId, OperationDate) with (online=on)
--insert dbo.br13304
select 
    d.BusinessDate
    , d.DateRegistered
    , d.ProductId
    , d.Sum
    , d.RawSum
    , d.State
    , c.id as clientid
    , concat(c.LastName, ' ', c.FirstName, ' ', c.FatherName) as fio
    , p.ContractNumber
    , p.CreatedOn
    , ld.LoginDate
    , cd.PropertyValue as CompanyDetails
    , N'OverdueAndNoDiscount' as Type
    , null as Notices
from doc.CompanyDetails cd, #Discounts d
left join prd.vw_product p on p.Productid = d.ProductId
left join client.Client c on c.id = p.ClientId
outer apply
(
    select min(cal.OperationDate) as LoginDate
    from client.ClientActionLog cal
    where cal.ClientId = p.ClientId
        and cal.OperationType = 1
        and cal.OperationDate > d.BusinessDate
) ld
where 1=1
    and
    (
        exists
        (
            select 1 from prd.vw_product p
            where p.Productid = d.Productid
                and p.PrivilegeFactor = 1
        )
        or
        exists
        (
            select 1 from prd.vw_statusLog sl
            where sl.Productid = d.Productid
                and sl.Status = 4
        )
    )
    and not exists
    (
        select 1 from ecc.Notice n
        where n.ClientId = d.ClientId
            and n.ProductId = d.Productid
            and n.TemplateUuid = '48B48662-4987-4158-87DE-17D43A70099A'    
    )
    and cd.PropertyName = 'OrgTitleShort'
order by p.Productid
/

--insert ecc.Notice
--(
--    AvailableFrom,ClientId,CreatedBy,CreatedOn,ReadDate,NoticeShowType,NoticeType,ProductId,TemplateUuid,Text
--)
select
    b.BusinessDate as AvailableFrom
    , b.ClientId
    , 0x44 as CreatedBy
    , dateadd(hour, 1, b.BusinessDate) as CreatedOn
    , dateadd(minute, 1, b.LoginDate) as ReadDate
    , 1 as NoticeShowType
    , 3 as NoticeType
    , b.ProductId
    , d.Uuid as TemplateUuid
    , replace(replace(replace(replace(replace(replace(d.Template
            , '{{Fio}}', b.Fio)
            , '{{DateNow}}', format(b.BusinessDate, 'dd/MM/yyyy'))
            , '{{ContractNumber}}', b.ContractNumber)
            , '{{ContractDate}}', format(b.CreatedOn, 'dd/MM/yyyy'))
            , '{{DiscountAmount}}', b.RawSum)
            , '{{CreditorCompany}}', b.CompanyDetails) as Text
from doc.CommunicationTemplate d, dbo.br13304 b
where b.Type = N'OverdueAndNoDiscount'
    and d.id = 1760
/

select d.BusinessDate, d.RawSum, p.CreatedOn, p.ContractNumber, n.*
from ecc.Notice n
inner join prd.vw_product p on p.ClientId = n.ClientId
    and p.Productid = n.ProductId
inner join #Discounts d on d.productId = n.productId
where n.ClientId = 2336644
    and n.TemplateUuid = '48B48662-4987-4158-87DE-17D43A70099A'   
/
