/*
declare @ClientId int = 1398639
;
*/

declare 
    @Billnumber varchar(20) = concat(1, 1000000000 - @ClientId, 1, 1000000000 - reverse(@ClientId))
    ,@Billnumber2 varchar(20) = concat(1, 1000000000 - @ClientId * 2, 1, 1000000000 - reverse(@ClientId * 2))
    ,@Pin nvarchar(6) = right(checksum(999999 + @ClientId), 6)
;

/*
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
    and cast(DateRegistered as date) between '20171026' and '20180615'
    and exists 
        (
            select 1
            from client.UserStatusHistory ush
            where ush.ClientId = c.clientid
                and ush.SubStatus >= 102
                and cast(ush.CreatedOn as date) <= '20180615'
        )
;

select distinct
    Uth.UserId as ClientId
into #OldTariff
from "LIME-DB".LimeZaim_Website.dbo.UserTariffHistory uth
where uth.Userid in (select ClientId from #c)
;


select
    c.*
    ,ni.IdentSuccess
into #is
from #c c
left join #OldTariff ot on ot.ClientId = c.ClientId
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

*/
select
    c.*
    ,CheckpayReq.q as CheckpayReq
    ,CheckpayRes.q as CheckpayRes
    ,FindcheckReq.q as FindcheckReq
    ,FindcheckRes.q as FindcheckRes
    ,PayReq.q as PayReq
    ,PayRes.q as PayRes
    ,FindpayReq.q as FindpayReq
    ,FindpayRes.q as FindpayRes
from dbo.TempClientIdent c
outer apply
(
    select 
        concat(N'https://pay.creditpilot.ru:8080/KPDealerWeb/KPBossHttpServer?actionName=CHECKPAY&dealerTransactionId=22&paymentType=16010&serviceProviderId=896638568&phoneNumber='
            ,c.PhoneNumber
            ,'&params[''passport'']='
            ,c.Passport 
            ,'&params[''passport_issued_at'']=' + format(c.PassportIssuedOn, 'dd.MM.yyyy')
            ,'&params[''snils'']=' + c.SNILS
            ,'&params[''inn'']=' + c.INN
            ,'&params[''last_name'']=' + LastName
            ,'&params[''first_name'']=' + FirstName
            ,'&params[''patronymic'']=' + FatherName
            ,'&params[''birth_date'']=' + format(c.BirthDate, 'dd.MM.yyyy')
            ,'&mode=' + case when c.SNILS is null then 'inn' end
        ) as q
) CheckpayReq
outer apply
(
    select 
        concat(N'<?xml version="1.0" encoding="UTF-8" ?>' + char(10)
                ,'<kp-dealer version="2.0">' + char(10)
                ,'<billnumber>'
                ,@Billnumber
                ,'</billnumber>' + char(10)
                ,'</kp-dealer>'
        ) as q
) CheckpayRes
outer apply
(
    select 'https://pay.creditpilot.ru:8080/KPDealerWeb/KPBossHttpServer?actionName=FINDCHECK&billNumber=' + @Billnumber as q
) FindcheckReq
outer apply
(
    select 
        concat(
            '<?xml version="1.0" encoding="UTF-8" ?>' + char(10)
            ,'<kp-dealer version="2.0">' + char(10)
            ,'<payment version="2.0" billNumber="'
            ,@Billnumber + '">' + char(10)
            ,'<tsDateSp>' + format(dateadd(s, 10, c.DateRegistered), 'MMM dd, yyyy h:mm:ss tt') + '</tsDateSp>' + char(10)
            ,'<tsDateDealer>' + format(dateadd(s, 5, c.DateRegistered), 'MMM dd, yyyy h:mm:ss tt') + '</tsDateDealer>' + char(10)
            ,'<checkPayData>' + char(10) + '<stepsLeft>0</stepsLeft>' + char(10)
            ,'<checkPayMap></checkPayMap>' + char(10)
            ,'<checkPayTable>' + char(10)
            ,N'<checkPayTableRow billingName="pin" title="Код подтверждения, 6 цифр" value="' /*+ @Pin*/ + '" editable="true"/>' + char(10)
            ,'</checkPayTable>' + char(10) + '</checkPayData></payment>' + char(10)
            ,'</kp-dealer>'
        ) as q
) FindcheckRes
outer apply
(
    select 
        concat(
            'https://pay.creditpilot.ru:8080/KPDealerWeb/KPBossHttpServer?actionName=PAY&dealerTransactionId=22&serviceProviderId=896638568&phoneNumber='
            ,c.PhoneNumber
            ,'&params[''passport'']='
            ,c.Passport 
            ,'&params[''passport_issued_at'']=' + format(c.PassportIssuedOn, 'dd.MM.yyyy')
            ,'&params[''snils'']=' + c.SNILS
            ,'&params[''inn'']=' + c.INN
            ,'&params[''last_name'']=' + LastName
            ,'&params[''first_name'']=' + FirstName
            ,'&params[''patronymic'']=' + FatherName
            ,'&params[''birth_date'']=' + format(c.BirthDate, 'dd.MM.yyyy')
            ,'&mode=' + case when c.SNILS is null then 'inn' end
            ,'params[''pin'']=' + @Pin
        ) as q
) PayReq
outer apply
(
    select 
        concat(
            '<?xml version="1.0" encoding="UTF-8" ?>' + char(10) + '<kp-dealer version="2.0">' + char(10)
            ,'<billNumber>' + @Billnumber2 + '</billNumber>'
            ,'<tsDateSp>' + format(dateadd(s, 15, c.DateRegistered), 'dd.MM.yyyy HH:mm:ss')+ '</tsDateSp>' + char(10)
            ,'<tsDateDealer>' + format(dateadd(s, 15, c.DateRegistered), 'dd.MM.yyyy HH:mm:ss')+ '</tsDateDealer>' + char(10)
            ,'<amount>0.0</amount>' + char(10)
            ,N'<result resultCode="0" resultDescription="Операция выполнена успешно"/>' + char(10) + '</kp-dealer>'
        ) q
) PayRes
outer apply
(
    select 'https://pay.creditpilot.ru:8080/KPDealerWeb/KPBossHttpServer?actionName=FINDPAY&billNumber=' + @Billnumber2 as q
) FindpayReq
outer apply
(
    select 
        concat(
            '<?xml version="1.0" encoding="UTF-8" ?>' + char(10)
            ,'<kp-dealer version="2.0">' + char(10)
	        ,'<payment version="2.0" billNumber="' + @Billnumber2 + ' "dealerTransactionId="22" remoteCheckId="">' + char(10)
            ,'<tsDateSp>' + format(dateadd(s, 20, c.DateRegistered), 'MMM dd, yyyy h:mm:ss tt') + '</tsDateSp>' + char(10)
            ,'<tsDateDealer>' + format(dateadd(s, 15, c.DateRegistered), 'MMM dd, yyyy h:mm:ss tt') + '</tsDateDealer>' + char(10)
            ,'<userData>' + char(10)
		    ,'<phoneNumber>' + c.PhoneNumber + '</phoneNumber>'  + char(10) 
		    ,'<serviceProviderId>896638568</serviceProviderId>' + char(10)
		    ,'<amount>0</amount>' + char(10) + '<fullAmount>0</fullAmount>' + char(10)
	        ,'</userData>' + char(10) + '<extras>' + char(10)
            ,'<extra name="person_valid" value="' + iif(c.IdentSuccess = 1, 'true', 'false') + '"/>' + char(10)
            ,'<extra name="passport_valid" value="' + iif(c.IdentSuccess = 1, 'true', 'false') + '"/>' + char(10)
            ,case when c.SNILS is not null then '<extra name="snils_valid" value="' + iif(c.IdentSuccess = 1, 'true', 'false') + '"/>' end + char(10)
            ,case when c.INN is not null then '<extra name="inn_valid" value="' + iif(c.IdentSuccess = 1, 'true', 'false') + '"/>' end + char(10)
            ,'</extras>' + char(10) + N'<result resultCode="1" resultDescription="Проведен" providerResultMessage="Проведен" fatal="true"/>' + char(10)
            ,'</payment>' + char(10) + '</kp-dealer>'
        ) as q
) FindpayRes
where c.clientid = @ClientId