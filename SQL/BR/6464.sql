select
    c.UserId
    , fu.Lastname
    , fu.Firstname
    , fu.Fathername
    , isnull(uai.FactRegion, uai.RegRegion) as Region
    , c.Id as CreditId
    , c.DateStarted
    , cs.Description as CreditStatus
    , c.Amount
    , c.IpAddress
    , p.CardNumber
from dbo.Credits c
inner join dbo.Payments p on p.Id = c.BorrowPaymentId
inner join dbo.FrontendUsers fu on fu.id = c.UserId
left join dbo.EnumDescriptions cs on cs.Id = c.Status
    and cs.Name = 'CreditStatus'
left join dbo.UserAdminInformation uai on uai.UserId = c.UserId
where c.DateCreated >= '20181101'
    and c.DateCreated < '20190121'
    and p.CardNumber like '469395%'
    and c.Way = -3
/
select
    c.Id as ClientId
    , c.LastName
    , c.FirstName
    , c.FatherName
    , isnull(af.Region, ar.Region) as Region
    , p.Productid
    , p.StartedOn
    , p.StatusName
    , p.Amount
    , c.IpAddress
    , cc.NumberMasked
from prd.vw_product p
inner join pmt.Payment pay on pay.ContractNumber = p.ContractNumber
    and pay.PaymentDirection = 1
inner join pmt.CreditCardPaymentInfo ccpi on ccpi.PaymentId = pay.id 
inner join client.CreditCard cc on cc.id = ccpi.CreditCardId
inner join client.Client c on c.Id = p.ClientId
left join client.vw_address ar on ar.ClientId = p.ClientId
    and ar.AddressType = 1
left join client.vw_address af on af.ClientId = p.ClientId
    and af.AddressType = 2
where p.CreatedOn >= '20181101'
    and p.CreatedOn < '20190121'
    and pay.PaymentWay = 1
    and cc.NumberMasked like '469395%'