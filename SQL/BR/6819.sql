select count(*)
from client.vw_Client c
where Passport is not null
    and not exists 
    (
        select 1 from client.ClientCardLog ccl
        where ccl.ClientId = c.clientid 
    )
    
select top 100 *
from client.ClientCardLog
/
insert Client.ClientCardLog
(
    ClientId
    , LastName
    , FirstName
    , FatherName
    , BirthDate
    , SexKind
    , MobilePhone
    , HomePhone
    , Email
    , Passport
    , PassportIssuedOn
    , PassportIssuedBy
    , BirthPlace
    , AdditionalPhone
    , ParentPhone
    , RegAddressStr
    , FactAddressStr
    , RegAddressIsFact
    , EducationType
    , EmploymentType
    , OrganizationName
    , "Position"
    , MaritalStatusKind
    , ChildrenKind
    , Income
    , INN
    , SNILS
    , DateRegistered
    , CreatedOn
    , CreatedBy
)
select
    c.ClientId
    , c.LastName
    , c.FirstName
    , c.FatherName
    , c.BirthDate
    , c2.SexKind
    , c.PhoneNumber as MobilePhone
    , p.PhoneNumber as HomePhone
    , c.Email
    , c.Passport
    , c.IssuedOn as PassportIssuedOn
    , c.IssuedBy as PassportIssuedBy
    , c.BirthPlace
    , pa.PhoneNumber as AdditionalPhone
    , pp.PhoneType as ParentPhone
    , isnull(ar.AddressStr, '') as RegAddressStr
    , isnull(af.AddressStr, '') as FactAddressStr
    , c.RegAddressIsFact
    , c2.EducationType
    , e.EmploymentType
    , e.OrganizationName
    , e."Position"
    , c2.MaritalStatusKind
    , c2.ChildrenKind
    , c.Income
    , c.INN
    , c.SNILS
    , c.DateRegistered
    , c.DateRegistered as CreatedOn
    , 0x44 as CreatedBy
from client.vw_Client c
inner join Client.Client c2 on c2.id = c.clientid
left join client.Address ar on ar.ClientId = c.clientid
    and ar.AddressType = 1
left join client.Address af on af.ClientId = c.clientid
    and af.AddressType = 2
left join client.Phone p on p.ClientId = c.clientid
    and p.PhoneType = 2 
left join client.Phone pa on pa.ClientId = c.clientid
    and pa.PhoneType = 5
left join client.Phone pp on pp.ClientId = c.clientid
    and pp.PhoneType = 5
left join client.Employment e on e.ClientId = c.clientid
where c.clientid != 615662  
    and c.Passport is not null
    and not exists 
    (
        select 1 from client.ClientCardLog ccl
        where ccl.ClientId = c.clientid 
            and ccl.CreatedOn <
    )
    
/

select *
from client.ClientCardLog
where clientid = 615662  