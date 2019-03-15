/* Манго */
select
    c.clientid
    , c.LastName
    , c.FirstName
    , c.FatherName
    , c.PhoneNumber
    , iif(c.EmailConfirmed = 1, c.Email, null) as Email
    , c.BirthDate
    , concat(ar.AddressStr, N', кв. ' + nullif(ar.Apartment, '')) as RegAddress
    , isnull(
        nullif(concat(af.AddressStr, N', кв. ' + nullif(af.Apartment, '')), '')
        , concat(ar.AddressStr, N', кв. ' + nullif(ar.Apartment, ''))) as FactAddress
    , p.Productid
    , p.ContractNumber
    , p.StartedOn
    , cpd.TotalDebt
    , dateadd(d, -cpd.OverdueDays + 1, cpd.Date) as OverdueStart
from prd.vw_Product p
inner join client.vw_client c on c.clientid = p.ClientId
left join client.Address ar on ar.ClientId = c.clientid
    and ar.AddressType = 1
left join client.Address af on af.ClientId = c.clientid
    and af.AddressType = 2
cross apply
(
    select top 1
        cpd.Date
        , cpd.TotalDebt
        , cpd.OverdueDays
    from bi.CollectorPortfolioDetail cpd
    where cpd.ProductId = p.ProductId
        and cpd.Date between '20181111' and '20181231'
        and cpd.GroupId between 2 and 4
    order by cpd.Date
) cpd
where exists
    (
        select 1
        from bi.CollectorPortfolioDetail cpd
        where cpd.ProductId = p.ProductId
            and cpd.Date between '20181111' and '20181231'
            and cpd.GroupId between 2 and 4
    )
/
/* Лайм */
select
    c.clientid
    , c.LastName
    , c.FirstName
    , c.FatherName
    , c.PhoneNumber
    , iif(c.EmailConfirmed = 1, c.Email, null) as Email
    , c.BirthDate
    , concat(ar.AddressStr, N', кв. ' + nullif(ar.Apartment, '')) as RegAddress
    , isnull(
        nullif(concat(af.AddressStr, N', кв. ' + nullif(af.Apartment, '')), '')
        , concat(ar.AddressStr, N', кв. ' + nullif(ar.Apartment, ''))) as FactAddress
    , p.Productid
    , p.ContractNumber
    , p.StartedOn
    , cpd.TotalDebt
    , dateadd(d, -cpd.OverdueDays + 1, cpd.Date) as OverdueStart
from prd.vw_Product p
inner join client.vw_client c on c.clientid = p.ClientId
left join client.Address ar on ar.ClientId = c.clientid
    and ar.AddressType = 1
left join client.Address af on af.ClientId = c.clientid
    and af.AddressType = 2
cross apply
(
    select top 1
        cpd.Date
        , cpd.TotalDebt
        , cpd.OverdueDays
    from bi.CollectorPortfolioDetail cpd
    where cpd.ProductId = p.ProductId
        and cpd.Date between '20180701' and '20181231'
        and cpd.GroupId between 2 and 4
        and CollectorId not in ('6AC8499E-B1DA-4C3C-8C00-BAF6488E3207','DE66079B-D589-406B-AB41-CA1E1588F84F','21CB2B99-B129-4794-B1CA-396172409DB2')
    order by cpd.Date
) cpd
where exists
    (
        select 1
        from bi.CollectorPortfolioDetail cpd
        where cpd.ProductId = p.ProductId
            and cpd.Date between '20180701' and '20181231'
            and cpd.GroupId between 2 and 4
            and CollectorId not in ('6AC8499E-B1DA-4C3C-8C00-BAF6488E3207','DE66079B-D589-406B-AB41-CA1E1588F84F','21CB2B99-B129-4794-B1CA-396172409DB2')
    )