drop table if exists #step
;

select
    p.Productid
    , p.ContractNumber
    , p.ClientId
    , p.Psk
    , p.StartedOn
    , p.Period
    , p.Amount
    , p.DatePaid
    , l.CurrentDate
    , l.SumReturn
    , l.OverPayment
    , l.ActualGroup
    , cast(l.PercentChangeDate as date) as PercentChangeDate
into #step
from dbo.br7109 l
inner join prd.vw_product p on p.Productid = l.ProductId
;
/
select 
    p.Productid
    , p.ContractNumber as DogovorNumber 
    , convert(varchar(25), p.CurrentDate, 126) as Date
    , convert(varchar(25), p.CurrentDate, 126) as Time -- add aggreement sign time
    , p.Amount as "Sum"
    , json_value(cdm.Command, '$.ZaimInfo') as ZaimInfo
    , p.SumReturn
    , p.SumReturn + p.OverPayment as SumPayment
    , p.OverPayment
    , p.ActualGroup
    , p.Psk
    , p.Psk as YearPercent 
    , sms.SmsCode
    , dateadd(d, p.Period, p.StartedOn) as DateReturn
    , p.Period
    , p.PercentChangeDate as DateOfChanePercentStart
    , cpe.DateOfChanePercentEnd
    , 0 as ChangedYearPercent
    , convert(varchar(25), cast(p.StartedOn as datetime), 126) as AgreementDate
    , ccl.*
    , pc.PercentConditions
    , com.PaidCommission as PaymentWayCommission
    , cast(0 as bit) as IsPrivile
from #step p
outer apply
(
    select sum(cb.Commission) as PaidCommission
    from bi.CreditBalance cb
    where cb.ProductId = p.Productid
        and cb.InfoType = 'payment'
) com
outer apply
(
    select min(StartedOn) as OverdueStart
    from prd.vw_statusLog sl
    where sl.ProductId = p.Productid
        and sl.Status = 4 
) os
outer apply
(
    select 
        isnull
            (
                cast(dateadd(ms, -999, p.DatePaid) as datetime)
                , dateadd(d, p.Period, p.StartedOn)
            ) as DateOfChanePercentEnd
) cpe
outer apply
(
    select top 1 cdm.Command
    from doc.ClientDocumentMetadata cdm 
    where cdm.ClientId = p.ClientId 
        and cdm.ContractNumber = p.ContractNumber
        and cdm.DocumentType = 101
) cdm
outer apply
(
    select top 1 json_value(cdm.Command, '$.SmsCode') as SmsCode
    from doc.ClientDocumentMetadata cdm 
    where cdm.ClientId = p.ClientId 
        and cdm.ContractNumber = p.ContractNumber
        and cdm.DocumentType in (101, 105)
        and cdm.CreatedOn <= p.CurrentDate
    order by cdm.CreatedOn desc
) sms
outer apply 
( 
    select top 1 a.IpAddress -- ip при авторизации
    from client.ClientActionLog a
    where a.ClientId = p.ClientId
        and a.ContractNumber = p.ContractNumber
        and cast(a.CreatedOn as date) = cast(p.DatePaid as date)
) ip
outer apply
(
    select top 1 
        rtrim(concat(ccl.LastName, ' ', ccl.FirstName, ' ', ccl.FatherName)) as fio
        , ccl.BirthDate
        , ccl.BirthPlace
        , ccl.Passport
        , ccl.PassportIssuedOn
        , ccl.PassportIssuedBy
        , ccl.RegAddressStr
        , ccl.FactAddressStr
        , ccl.MobilePhone
        , ccl.Email
        , isnull(ip.IpAddress, json_value(cdm.Command, '$.IpAddress')) as IpAddress
        , ccl.INN
        , ccl.SNILS
    from client.ClientCardLog ccl
    where ccl.ClientId = p.ClientId
        and ccl.CreatedOn < p.CurrentDate
    order by ccl.CreatedOn desc
) ccl
outer apply
(
    select 
        case p.ActualGroup
            when 1
            then N'Основная процентная ставка по Договору составляет 0 процентов годовых.'
            when 2
            then N'Основная процентная ставка по Договору составляет ' 
                + cast(p.Psk as nvarchar(10)) + N' процентов годовых.' + char(10) + char(10)
                + N'В период с ' + format(p.PercentChangeDate, 'dd.MM.yyyy') 
                + N' по ' + format(cpe.DateOfChanePercentEnd, 'dd.MM.yyyy')
                + N' процентная ставка по Договору составляет 0 процентов годовых.'
            when 3
            then N'Основная процентная ставка по Договору составляет ' 
                + cast(p.Psk as nvarchar(10)) + N' процентов годовых.' + char(10)
                + N'В период с ' + format(p.PercentChangeDate, 'dd.MM.yyyy')
                + N' процентная ставка по Договору составляет 0 процентов годовых.'
                + N'В период с ' + format(p.PercentChangeDate, 'dd.MM.yyyy') 
                + N' по ' + format(cpe.DateOfChanePercentEnd, 'dd.MM.yyyy')
                + N' проценты по Договору не начисляются.'
            when 4
            then N'Основная процентная ставка по Договору составляет ' 
                + cast(p.Psk as nvarchar(10)) + N' процентов годовых.' + char(10) + char(10)
                + N'В период с ' + format(p.PercentChangeDate, 'dd.MM.yyyy') 
                + N' по ' + format(cpe.DateOfChanePercentEnd, 'dd.MM.yyyy')
                + N' проценты по Договору не начисляются.'
         end as PercentConditions
) pc
where ActualGroup like '[1234]'