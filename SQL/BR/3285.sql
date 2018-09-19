drop table if exists #Mango
;

select
    c.UserId as ClientId
    ,cs.ClientStatus
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,c.id as BACanceledCreditId
    ,c.DogovorNumber as BACanceledContractNumber
    ,c.DateCreated as BACanceledDateCreated
    ,c.Amount as BACanceledAmount
    ,ba.AccountNum
    ,c2.id as NextCreditId
    ,c2.DogovorNumber as NextCreditContractNumber
    ,c2.Amount as NextCreditAmount
    ,c2.Way as NextCreditWay
    ,c2.Status as NextCreditStatus
    ,cb.Amount
    ,cb.PercentAmount
    ,cb.TransactionCosts
    ,cb.PenaltyAmount
into #Mango
from "MANGO-DB".Limezaim_Website.dbo.Credits c with (nolock)
inner join "MANGO-DB".Limezaim_Website.dbo.Payments p with (nolock) on p.id = c.BorrowPaymentid
inner join "MANGO-DB".Limezaim_Website.dbo.BankAccounts ba with (nolock) on ba.id = p.BankAccountId
inner join "MANGO-DB".Limezaim_Website.dbo.Frontendusers fu with (nolock) on fu.id = c.userId
outer apply
(
    select top 1
        cs.Description as ClientStatus
    from "MANGO-DB".Limezaim_Website.dbo.UserStatusHistory ush with (nolock)
    inner join "MANGO-DB".Limezaim_Website.dbo.EnumDescriptions cs with (nolock) on cs.Value = ush.Status
        and cs.Name = 'UserStatusKind'
    where ush.UserId = c.UserId
    order by ush.DateCreated desc
) cs
outer apply
(
    select top 1
        c2.id
        ,c2.Amount
        ,c2.DogovorNumber
        ,mw.Description as Way
        ,cs.Description as Status
    from "MANGO-DB".Limezaim_Website.dbo.Credits c2 with (nolock)
    inner join "MANGO-DB".Limezaim_Website.dbo.EnumDescriptions mw on mw.value = c2.Way
        and mw.Name = 'MoneyWay'
    inner join "MANGO-DB".Limezaim_Website.dbo.EnumDescriptions cs on cs.value = c2.Status
        and cs.Name = 'CreditStatus'
    where c2.UserId = c.UserId
        and c2.DateCreated > c.DateCreated
    order by c2.DateCreated
) c2
outer apply
(
    select top 1
        Amount
        ,PercentAmount
        ,CommisionAmount
        ,PenaltyAmount
        ,TransactionCosts
    from "MANGO-DB".Limezaim_Website.dbo.CreditBalances cb with (nolock)
    where cb.CreditId = c2.id
    order by cb.Date
) cb
where c.Way = -2
    and c.Status = 8
    and c.DateCreated >= '20180101'
;

drop table if exists #Konga
;

select
    c.UserId as ClientId
    ,cs.ClientStatus
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,c.id as BACanceledCreditId
    ,c.DogovorNumber as BACanceledContractNumber
    ,c.DateCreated as BACanceledDateCreated
    ,c.Amount as BACanceledAmount
    ,ba.AccountNum
    ,c2.id as NextCreditId
    ,c2.DogovorNumber as NextCreditContractNumber
    ,c2.Amount as NextCreditAmount
    ,c2.Way as NextCreditWay
    ,c2.Status as NextCreditStatus
    ,cb.Amount
    ,cb.PercentAmount
    ,cb.TransactionCosts
    ,cb.PenaltyAmount
into #Konga
from "KONGA-DB".Limezaim_Website.dbo.Credits c with (nolock)
inner join "KONGA-DB".Limezaim_Website.dbo.Payments p with (nolock) on p.id = c.BorrowPaymentid
inner join "KONGA-DB".Limezaim_Website.dbo.BankAccounts ba with (nolock) on ba.id = p.BankAccountId
inner join "KONGA-DB".Limezaim_Website.dbo.Frontendusers fu with (nolock) on fu.id = c.userId
outer apply
(
    select top 1
        cs.Description as ClientStatus
    from "MANGO-DB".Limezaim_Website.dbo.UserStatusHistory ush with (nolock)
    inner join "MANGO-DB".Limezaim_Website.dbo.EnumDescriptions cs with (nolock) on cs.Value = ush.Status
        and cs.Name = 'UserStatusKind'
    where ush.UserId = c.UserId
    order by ush.DateCreated desc
) cs
outer apply
(
    select top 1
        c2.id
        ,c2.Amount
        ,c2.DogovorNumber
        ,mw.Description as Way
        ,cs.Description as Status
    from "KONGA-DB".Limezaim_Website.dbo.Credits c2 with (nolock)
    inner join "KONGA-DB".Limezaim_Website.dbo.EnumDescriptions mw on mw.value = c2.Way
        and mw.Name = 'MoneyWay'
    inner join "KONGA-DB".Limezaim_Website.dbo.EnumDescriptions cs on cs.value = c2.Status
        and cs.Name = 'CreditStatus'
    where c2.UserId = c.UserId
        and c2.DateCreated > c.DateCreated
    order by c2.DateCreated
) c2
outer apply
(
    select top 1
        Amount
        ,PercentAmount
        ,CommisionAmount
        ,PenaltyAmount
        ,TransactionCosts
    from "KONGA-DB".Limezaim_Website.dbo.CreditBalances cb with (nolock)
    where cb.CreditId = c2.id
    order by cb.Date
) cb
where c.Way = -2
    and c.Status = 8
    and c.DateCreated >= '20180101'
;

drop table if exists #OP
;

select
    c.UserId as ClientId
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,c.id as BACanceledCreditId
    ,c.DogovorNumber as BACanceledContractNumber
    ,c.DateCreated as BACanceledDateCreated
    ,c.Amount as BACanceledAmount
    ,ba.AccountNum
    ,c2.id as NextCreditId
    ,c2.DogovorNumber as NextCreditContractNumber
    ,c2.Amount as NextCreditAmount
    ,c2.Way as NextCreditWay
    ,c2.Status as NextCreditStatus
into #OP
from "LIME-DB".Limezaim_Website.dbo.Credits c with (nolock)
inner join "LIME-DB".Limezaim_Website.dbo.Payments p on p.id = c.BorrowPaymentid
inner join "LIME-DB".Limezaim_Website.dbo.BankAccounts ba with (nolock) on ba.id = p.BankAccountId
inner join "LIME-DB".Limezaim_Website.dbo.Frontendusers fu with (nolock) on fu.id = c.userId
outer apply
(
    select top 1
        c2.id
        ,c2.Amount
        ,c2.DogovorNumber
        ,mw.Description as Way
        ,cs.Description as Status
    from "LIME-DB".Limezaim_Website.dbo.Credits c2 with (nolock)
    inner join "LIME-DB".Limezaim_Website.dbo.EnumDescriptions mw on mw.value = c2.Way
        and mw.Name = 'MoneyWay'
    inner join "LIME-DB".Limezaim_Website.dbo.EnumDescriptions cs on cs.value = c2.Status
        and cs.Name = 'CreditStatus'
    where c2.UserId = c.UserId
        and c2.DateCreated > c.DateCreated
    order by c2.DateCreated
) c2
where c.Way = -2
    and c.Status = 8
    and c.DateCreated >= '20180101'
;

with op as 
(
    select
        op.ClientId
        ,c.substatusName as ClientStatus
        ,op.fio
        ,op.BACanceledCreditId
        ,op.BACanceledContractNumber
        ,op.BACanceledDateCreated
        ,op.BACanceledAmount
        ,op.AccountNum
        ,isnull(op.NextCreditId, pn.Productid) as NextCreditId
        ,isnull(op.NextCreditContractNumber, pn.ContractNumber) as NextCreditContractNumber
        ,isnull(op.NextCreditAmount, pn.Amount) as NextCreditAmount
        ,isnull(op.NextCreditWay, pn.PaymentWay) as NextCreditWay
        ,isnull(p.StatusName, op.NextCreditStatus) as NextCreditStatus
        ,cb.*
    from #OP op
    inner join client.vw_client c on c.ClientId = op.ClientId
    left join prd.vw_product p on p.Productid = op.NextCreditId
    outer apply
    (
        select top 1 
            pn.Productid
            ,pn.ContractNumber
            ,pn.Amount
            ,pn.PaymentWay
        from prd.vw_product pn
        where pn.CreatedOn > op.BACanceledDateCreated
            and pn.ClientId = op.ClientId
            and op.NextCreditId is null
        order by pn.CreatedOn    
    ) pn
    outer apply
    (
        select top 1 
            cb.TotalAmount
            ,cb.TotalPercent
            ,cb.Commission
            ,cb.Fine
        from bi.CreditBalance cb
        where cb.ProductId = isnull(op.NextCreditId, pn.Productid)
            and cb.InfoType = 'debt'
        order by cb.DateOperation desc
    ) cb
)

select
    'Lime' as Project 
    ,c.clientid
    ,c.substatusName as ClientStatus
    ,c.fio
    ,p.Productid as BACanceledCreditId
    ,p.ContractNumber as BACanceledContractNumber
    ,p.CreatedOn as BACanceledDateCreated
    ,p.Amount as BACanceledAmount
    ,ba.AccountNum
    ,pn.Productid as NextCreditId
    ,pn.ContractNumber as NextCreditContractNumber
    ,pn.Amount as NextCreditAmount
    ,pn.PaymentWayName as NextCreditWay
    ,pn.StatusName as NextCreditStatus
    ,cb.*
from prd.vw_product p
inner join client.vw_client c on c.clientid = p.ClientId
left join pmt.Payment pay on pay.ContractNumber = p.ContractNumber
    and pay.PaymentDirection = 1
left join pmt.BankAccountPaymentInfo bapi on bapi.PaymentId = pay.Id
left join client.BankAccount ba on ba.Id = bapi.BankAccountId
outer apply
(
    select top 1
        p2.Productid
        ,p2.ContractNumber
        ,p2.Amount
        ,p2.PaymentWayName
        ,p2.StatusName
    from prd.vw_product p2
    where p2.ClientId = p.clientid
        and p2.CreatedOn > p.CreatedOn
    order by p2.CreatedOn
) pn
outer apply
(
    select top 1 
        cb.TotalAmount
        ,cb.TotalPercent
        ,cb.Commission
        ,cb.Fine
    from bi.CreditBalance cb
    where cb.ProductId = pn.Productid
        and cb.InfoType = 'debt'
    order by cb.DateOperation desc
) cb
where p.status = 1
    and p.PaymentWay = 2
    and p.CreatedOn >= '20180101'
    and p.Productid not in (select op.BACanceledCreditId from op)
    and p.Productid not in (select op.NextCreditId from op where op.NextCreditId is not null)

union all

select 'Lime', * from op

union all

select 'Konga', * from #Konga

union all

select 'Mango', * from #Mango

order by Project, BACanceledCreditId

/

select
    'Lime' as Project
    ,c.id as CreditId
    ,c.UserId as ClientId
    ,c.DogovorNumber as ContractNumber
    ,ba.AccountNum
    ,ps.Description as PaymentStatus
from "LIME-DB".Limezaim_Website.dbo.Credits c with (nolock)
inner join "LIME-DB".Limezaim_Website.dbo.Payments p with (nolock) on p.id = c.BorrowPaymentid
inner join "LIME-DB".Limezaim_Website.dbo.BankAccounts ba with (nolock) on ba.id = p.BankAccountId
inner join "LIME-DB".Limezaim_Website.dbo.Frontendusers fu with (nolock) on fu.id = c.userId
inner join "LIME-DB".Limezaim_Website.dbo.EnumDescriptions ps with (nolock) on ps.Name = 'PaymentStatus'
    and ps.Value = p.Status
inner join "LIME-DB".Limezaim_Website.dbo.EnumDescriptions cs with (nolock) on cs.Name = 'CreditStatus'
    and cs.Value = c.Status
where c.Way = -2
    and not exists 
        (
            select 1 from prd.product p
            where p.id = c.id
        )
    and ba.AccountNum not like '40817%'
    and ba.AccountNum not like '4230[1-7]%'
        
union all

select
    'Lime' as Project
    ,p.Productid
    ,p.ClientId
    ,p.ContractNumber
    ,ba.AccountNum
    ,ps.Description as PaymentStatus
from prd.vw_product p
inner join pmt.Payment pay on pay.ContractNumber = p.ContractNumber
    and pay.PaymentDirection = 1
inner join pmt.BankAccountPaymentInfo bapi on bapi.PaymentId = pay.Id
left join client.BankAccount ba on ba.Id = bapi.BankAccountId
left join pmt.EnumPaymentStatus ps on ps.id = pay.PaymentStatus
where p.PaymentWay = 2 
    and ba.AccountNum not like '40817%'
    and ba.AccountNum not like '4230[1-7]%'
    
union all

select
    'Konga' as Project
    ,c.id as CreditId
    ,c.UserId as ClientId
    ,c.DogovorNumber as ContractNumber
    ,ba.AccountNum
    ,ps.Description as PaymentStatus
from "KONGA-DB".Limezaim_Website.dbo.Credits c with (nolock)
inner join "KONGA-DB".Limezaim_Website.dbo.Payments p with (nolock) on p.id = c.BorrowPaymentid
inner join "KONGA-DB".Limezaim_Website.dbo.BankAccounts ba with (nolock) on ba.id = p.BankAccountId
inner join "KONGA-DB".Limezaim_Website.dbo.Frontendusers fu with (nolock) on fu.id = c.userId
inner join "KONGA-DB".Limezaim_Website.dbo.EnumDescriptions ps with (nolock) on ps.Name = 'PaymentStatus'
    and ps.Value = p.Status
inner join "KONGA-DB".Limezaim_Website.dbo.EnumDescriptions cs with (nolock) on cs.Name = 'CreditStatus'
    and cs.Value = c.Status
where c.Way = -2
    and ba.AccountNum not like '40817%'
    and ba.AccountNum not like '4230[1-7]%'
    
union all

select
    'Mango' as Project
    ,c.id as CreditId
    ,c.UserId as ClientId
    ,c.DogovorNumber as ContractNumber
    ,ba.AccountNum
    ,ps.Description as PaymentStatus
from "MANGO-DB".Limezaim_Website.dbo.Credits c with (nolock)
inner join "MANGO-DB".Limezaim_Website.dbo.Payments p with (nolock) on p.id = c.BorrowPaymentid
inner join "MANGO-DB".Limezaim_Website.dbo.BankAccounts ba with (nolock) on ba.id = p.BankAccountId
inner join "MANGO-DB".Limezaim_Website.dbo.Frontendusers fu with (nolock) on fu.id = c.userId
inner join "MANGO-DB".Limezaim_Website.dbo.EnumDescriptions ps with (nolock) on ps.Name = 'PaymentStatus'
    and ps.Value = p.Status
inner join "MANGO-DB".Limezaim_Website.dbo.EnumDescriptions cs with (nolock) on cs.Name = 'CreditStatus'
    and cs.Value = c.Status
where c.Way = -2
    and ba.AccountNum not like '40817%'
    and ba.AccountNum not like '4230[1-7]%'