drop table if exists #ClientInfo
;

select
    th.ClientId
    ,c.DateRegistered
    ,c.Passport
    ,c.PhoneNumber
    ,ph.PhoneNumber as AdditionalPhone
    ,h.name
    ,e.OrganizationName
    ,th.CreatedOn as TariffDate
    ,th.TariffName
    ,th.MaxAmount
    ,p.*
into #ClientInfo
from client.vw_TariffHistory th
inner join client.vw_Client c on c.clientid = th.ClientId
left join client.Phone ph on ph.ClientId = th.clientid
    and ph.PhoneType = 5
left join client.Address a on a.ClientId = th.ClientId
    and a.AddressType = 1
left join fias.dict.hierarchy h on h.regioncode = a.RegionId
    and h.aolevel = 1
left join client.Employment e on e.ClientId = th.ClientId
cross apply
(
    select
        p.Productid
        ,p.Amount
        ,p.PaymentWayName
        ,cc.NumberMasked
        ,isnull(p.StartedOn, p.CreatedOn) as ProductDate
        ,dateadd(d, p.Period, p.StartedOn) as ContractDate
        ,p.StatusName
    from prd.vw_product p
    inner join pmt.Payment pay on pay.ContractNumber = p.ContractNumber
        and pay.PaymentDirection = 1
        and pay.PaymentStatus = 5
    left join pmt.CreditCardPaymentInfo ccpi on ccpi.PaymentId = pay.id
    left join client.CreditCard cc on cc.id = ccpi.CreditCardId
    where p.ClientId = th.ClientId
        and p.ProductType = th.ProductType
        and p.CreatedOn >= th.CreatedOn
        and (th.ModifiedOn is null or p.CreatedOn < th.ModifiedOn)
        and p.CreatedOn >= '20180929'
        and not exists 
            (
                select 1 from client.vw_TariffHistory th2
                outer apply
                (
                    select min(v.dt) as MinDt from (values (th2.CreatedOn), (th2.ModifiedOn)) v(dt)
                ) v
                where th2.ClientId = th.ClientId
                    and v.MinDt > th.CreatedOn
            )
) p
where th.CreatedBy = '091E5F2C-DD61-47BA-B9A0-372C7C31BA6F'
;
/
with ch as (
SELECT 1271170 AS ClientId,'7518091717' AS Passport,'79127733566' AS PhoneNumber,'79049707747' AS AdditionalPhone,null AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,1 AS KongaPhoneDouble,1 AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,1 AS MangoPhoneDouble
UNION ALL
SELECT 1271170 AS ClientId,'7518091717' AS Passport,'79127733566' AS PhoneNumber,'79049707747' AS AdditionalPhone,null AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,1 AS KongaPhoneDouble,1 AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,1 AS MangoPhoneDouble
UNION ALL
SELECT 1412166 AS ClientId,'0406257556' AS Passport,'79833633546' AS PhoneNumber,'79831493726' AS AdditionalPhone,null AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,null AS KongaPhoneDouble,null AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,null AS MangoPhoneDouble
UNION ALL
SELECT 1496068 AS ClientId,'6016988834' AS Passport,'79882552024' AS PhoneNumber,'79896135794' AS AdditionalPhone,null AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,null AS KongaPhoneDouble,null AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,null AS MangoPhoneDouble
UNION ALL
SELECT 1763790 AS ClientId,'3407864403' AS Passport,'79536572101' AS PhoneNumber,'79502418349' AS AdditionalPhone,1 AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,1 AS KongaPhoneDouble,1 AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,1 AS MangoPhoneDouble
UNION ALL
SELECT 1972850 AS ClientId,'7106507064' AS Passport,'79097421743' AS PhoneNumber,'79829229481' AS AdditionalPhone,1 AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,1 AS KongaPhoneDouble,1 AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,1 AS MangoPhoneDouble
UNION ALL
SELECT 2030150 AS ClientId,'1400324256' AS Passport,'79103626831' AS PhoneNumber,'79601544434' AS AdditionalPhone,1 AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,null AS KongaPhoneDouble,1 AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,1 AS MangoPhoneDouble
UNION ALL
SELECT 2040614 AS ClientId,'9210065516' AS Passport,'79393951511' AS PhoneNumber,'79870667710' AS AdditionalPhone,1 AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,1 AS KongaPhoneDouble,1 AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,1 AS MangoPhoneDouble
UNION ALL
SELECT 2047995 AS ClientId,'0704302652' AS Passport,'79682619191' AS PhoneNumber,'79113575188' AS AdditionalPhone,1 AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,1 AS KongaPhoneDouble,1 AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,1 AS MangoPhoneDouble
UNION ALL
SELECT 2052572 AS ClientId,'3608950287' AS Passport,'79175455306' AS PhoneNumber,'79277271727' AS AdditionalPhone,1 AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,1 AS KongaPhoneDouble,1 AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,1 AS MangoPhoneDouble
UNION ALL
SELECT 2074546 AS ClientId,'2217705200' AS Passport,'79081676817' AS PhoneNumber,'79601787999' AS AdditionalPhone,null AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,null AS KongaPhoneDouble,1 AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,1 AS MangoPhoneDouble
UNION ALL
SELECT 2077131 AS ClientId,'3206045493' AS Passport,'79235216710' AS PhoneNumber,'79515928563' AS AdditionalPhone,1 AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,1 AS KongaPhoneDouble,null AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,null AS MangoPhoneDouble
UNION ALL
SELECT 2087471 AS ClientId,'9300012068' AS Passport,'79232654184' AS PhoneNumber,'79618941840' AS AdditionalPhone,null AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,null AS KongaPhoneDouble,1 AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,1 AS MangoPhoneDouble
UNION ALL
SELECT 2110348 AS ClientId,'6013474085' AS Passport,'79515093403' AS PhoneNumber,'79525837962' AS AdditionalPhone,1 AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,1 AS KongaPhoneDouble,1 AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,1 AS MangoPhoneDouble
UNION ALL
SELECT 2198536 AS ClientId,'6708819144' AS Passport,'79129025629' AS PhoneNumber,'79224196763' AS AdditionalPhone,1 AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,1 AS KongaPhoneDouble,1 AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,1 AS MangoPhoneDouble
UNION ALL
SELECT 2221311 AS ClientId,'5214382001' AS Passport,'79236714796' AS PhoneNumber,'79230352723' AS AdditionalPhone,1 AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,1 AS KongaPhoneDouble,1 AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,1 AS MangoPhoneDouble
UNION ALL
SELECT 2240507 AS ClientId,'4715517586' AS Passport,'79211729117' AS PhoneNumber,'79113447461' AS AdditionalPhone,null AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,null AS KongaPhoneDouble,null AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,null AS MangoPhoneDouble
UNION ALL
SELECT 2254208 AS ClientId,'9706457982' AS Passport,'79777189041' AS PhoneNumber,'79299890260' AS AdditionalPhone,1 AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,1 AS KongaPhoneDouble,null AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,null AS MangoPhoneDouble
UNION ALL
SELECT 2308125 AS ClientId,'9217269233' AS Passport,'79600625577' AS PhoneNumber,'79377731627' AS AdditionalPhone,1 AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,1 AS KongaPhoneDouble,1 AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,1 AS MangoPhoneDouble
UNION ALL
SELECT 2399928 AS ClientId,'5718730686' AS Passport,'79194710093' AS PhoneNumber,'79097306400' AS AdditionalPhone,1 AS KongaPassportDouble,null AS KongaAdditionalPhoneDouble,1 AS KongaPhoneDouble,1 AS MangoPassportDouble,null AS MangoAdditionalPhoneDouble,1 AS MangoPhoneDouble
)

select 
    ci.*
    ,ch.KongaPassportDouble
    ,ch.KongaAdditionalPhoneDouble
    ,ch.KongaPhoneDouble
    ,ch.MangoPassportDouble
    ,ch.MangoAdditionalPhoneDouble
    ,ch.MangoPhoneDouble
from #ClientInfo ci
inner join ch on ch.ClientId = ci.ClientId