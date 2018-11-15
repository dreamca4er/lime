with ces as 
(
    select
        c.Name as CessionName
        ,d.CreditId
        ,cr.DogovorNumber as ContractNumber
        ,cr.UserId as ClientId
    from LimeZaim_Website.dbo.DebtorTransferCession dtc
    inner join LimeZaim_Website.dbo.Debtors d on d.id = dtc.DebtorId
    inner join LimeZaim_Website.dbo.Cessions c on c.Id = dtc.CessionId
    inner join LimeZaim_Website.dbo.Credits cr on cr.Id = d.CreditId
)
   
select
    c.UserId as ClientId
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,c.id as ProductId
    ,c.DogovorNumber as ContractNumber
    ,c.DateStarted as StartedOn
    ,c.Period
    ,c.Amount
    ,pw.Description as PaymentWayname
    ,iif(c.TariffId = 4, N'ДЗ', N'КЗ') as ProductTypeName
    ,cb.Amount as AmountDebt
    ,cb.PercentAmount as PercentDebt
    ,cb.TransactionCosts as TransactionCostsDebt 
    ,cb.PenaltyAmount as FineDebt
from dbo.UserCards uc
inner join dbo.FrontendUsers fu on fu.id = uc.UserId
inner join dbo.Credits c on c.UserId = uc.UserId
    and c.Status in (1, 3)
inner join dbo.EnumDescriptions pw on pw.Name = 'MoneyWay'
    and pw.Value = c.Way
left join ces on ces.CreditId = c.id
outer apply
(
    select top 1
        cb.*
    from dbo.CreditBalances cb
    where cb.CreditId = c.id
    order by cb.Date desc
) cb
where
    (
        (uc.IsFraud = 1 and IsFraudDateChanged >= '20180101')
        or
        (uc.IsDied = 1 and IsDiedDateChanged >= '20180101')
    )
    and ces.CreditId is null