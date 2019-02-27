declare @ClientId int = 979236
;

declare 
    @Billnumber varchar(20) = concat(1, 1000000000 - @ClientId, 1, 1000000000 - reverse(@ClientId))
    ,@Billnumber2 varchar(20) = concat(1, 1000000000 - @ClientId * 2, 1, 1000000000 - reverse(@ClientId * 2))
    ,@Pin nvarchar(6) = right(checksum(999999 + @ClientId), 6)
;


drop table if exists #c
;

drop table if exists #d
;

drop table if exists #is
;

drop table if exists #OldTariff
;

select 
    c.ClientId
    ,right(c.PhoneNumber, 10) as PhoneNumber
    ,c.HaveInternalCredits
    ,c.Passport
    ,c.IssuedOn as PassportIssuedOn
    ,cast(left(c.Passport, 4) as int) as Series
    ,cast(right(c.Passport, 6) as int) as Number
    ,c.FirstName
    ,c.LastName
    ,c.FatherName
    ,c.BirthDate
    ,c.INN
    ,c.SNILS
    ,c.DateRegistered
into #c
from Client.vw_Client c
where 1=1
    and not ((SNILS = '00000000000' or SNILS is null)
    and (INN = '' or INN is null))
    and c.ClientId = @ClientId
;
/

--select distinct
--    Uth.UserId as ClientId
--into #OldTariff
--from "LIME-DB".LimeZaim_Website.dbo.UserTariffHistory uth
--where uth.Userid in (select ClientId from #c)
--;


select
    c.*
    ,ni.IdentSuccess
into #is
from #c c
--left join #OldTariff ot on ot.ClientId = c.ClientId
outer apply
(
    select top 1 1 as HadProduct
    from prd.Product p
    where p.ClientId = c.ClientId
) p
outer apply
(
    select top 1 1 as HadTariff
    from client.vw_TariffHistory th
    where th.ClientId = c.ClientId
) th
outer apply
(
    select top 1 1 as HasInvalidPassport 
    from cr.InvalidPassport ip
    where ip.Series = c.Series
        and ip.Number = c.Number
) ip
outer apply
(
    select top 1 1 as IsInBlackList
    from cr.BlackListUser blu
    where blu.FirstName = c.FirstName
        and blu.Lastname = c.LastName
        and (blu.Fathername = c.FatherName or blu.Fathername is null or c.FatherName is null)
        and (c.BirthDate = blu.Birthday or blu.Birthday is null or c.BirthDate is null)
        and (c.Passport like '%' + blu.Passports + '%' or c.Passport is null or blu.Passports is null)
) blu
outer apply
(
    select 
        case
--                when HadProduct = 1 
--                    or c.HaveInternalCredits = 1
--                    or th.HadTariff = 1
--                    or ot.ClientId is not null
--                then 1
            when blu.IsInBlackList = 1 or ip.HasInvalidPassport = 1
            then 0
            else 1 
        end as IdentSuccess
) ni


/*
alter table dbo.TempClientIdent
add IssueNum nvarchar(20)

insert dbo.TempClientIdent
select *, 'BR-6639'
from #is
*/