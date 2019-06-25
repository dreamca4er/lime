select 'a' + char(9) + 'b' 
select
    c.id as CreditId
    , cb.*
    , c.AgreementNumber
    , cast(c.DateStarted as date) as DateStarted
    , c.Period
    , os.OverdueStart
    , c.PayDay
    , cancel.CancelDate
    , cp.PaymentsCount
    , isnull(pcu.HadProlongations, 'No') as HadProlongations
    , cp.LastPaymentDate
    , cp.LastPaymentsAmount
    , replace(replace(replace(replace(replace(pl.plist
            , '/><row ', '},{"')
            , '<row ', '[{"')
            , '/>', '}]')
            , '=', '":')
            , ' ', ',"') as PaymentsList
    , (c.Amount - cb.Amount) / c.Amount as CurrentRepaymentOfDebt
    , case when d.PromisedPayDay is null then 'No' else 'Yes' end as HasPromise
    , case when ufh.id is null then 'No' else 'Yes' end as IsFraud
    , case
        when dsh.ObjectionAnswered = 1 then 'Answer to objection'
        when dsh.ObjectionRejected = 1 then 'Reject objection'
    end as DebtObjection
    , uc.Pesel
    , fu.Birthday
    , case uc.Gender
        when 1 then 'Male'
        when 2 then 'Female'
    end as Gender
    , ha.*
    , ra.*
    , ca.*
    , case when isnull(ra.ResidenceIsActive, 0) = 1 then 'Yes' else 'No' end as ResidenceIsActive
    , up.Phone
    , dch.*
    , case when isnull(dsh.IsDead, 0) = 1 then 'Yes' else 'No' end as IsDead
    , case when isnull(dsh.IsBankrupt, 0) = 1 then 'Yes' else 'No' end as IsBankrupt
    , case uc.Education
        when 1 then 'Basic'
        when 2 then 'Average'
        when 3 then 'Higher'
        when 4 then 'Vocational'
    end as Education
    , uc.Position
    , case uc.LevelPosition
        when 1 then 'Worker'
        when 2 then 'A specialist with higher education'
        when 3 then 'Head of the department'
        when 4 then 'Higher management team'
    end as JobType
    , cast(uc.Income as nvarchar(20)) + ' net' as Income
    , case uc.MaritalStatus
        when 1 then 'Not married'
        when 2 then 'Married'
        when 3 then 'Partnership'
        when 4 then 'Widow or widower'
    end as MaritalStatus
    , isnull(cast(uc.Children - 1 as nvarchar), '0') 
        + 
        case 
            when uc.Children = 5 then '+ children'
            when uc.Children = 2 then ' child'
            else ' children'
        end as Children
    , case 
        when datediff(d, os.OverdueStart, getdate()) > 365 * 3 
        then 'Yes' 
        else 'No' 
    end as IsTimeBarred
    , case 
        when datediff(d, os.OverdueStart, getdate()) > 365 * 3 
        then dateadd(d, 365 * 3, os.OverdueStart)
    end as TimeBarredDate
    , dsh.CollectionStartDate
    , case when dsh.ExecutionEntitlement = 1 then 'Yes' else 'No' end as ExecutionEntitlement
    , dsh.BailiffSentDate
    , br.BailiffResult
    , dsh.DiscontinuanceDate
    , dr.DiscontinuanceReason
from dbo.credits c
left join dbo.Debtors d on d.CreditId = c.Id
left join dbo.UserFraudHistory ufh on ufh.UserId = c.UserId
left join dbo.UserCards uc on uc.userid = c.UserId
left join dbo.FrontendUsers fu on fu.Id = c.UserId
outer apply
(
    select cast(max(csh.DateCreated) as date) as OverdueStart
    from dbo.CreditStatusHistory csh
    where csh.CreditId = c.id
) os
outer apply
(
    select top 1
        cb.Amount
        , cb.CommissionAmount
        , cb.PenaltyAmount
        , cb.Interest
    from dbo.CreditBalances cb
    where cb.CreditId = c.Id
    order by cb.Date desc
) cb
outer apply
(
    select cast(min(csh.DateCreated) as date) as CancelDate
    from dbo.CreditStatusHistory csh
    where csh.CreditId = c.id
        and csh.Status = 8
) cancel
outer apply
(
    select 
        case 
            when row_number() over (order by cp.DateCreated desc) = 1
            then 1 
            else 0 
        end as IsNeededEntry 
        , row_number() over (order by cp.DateCreated) as PaymentsCount
        , p.Amount as LastPaymentsAmount
        , cast(max(p.DateCreated) over () as date) as LastPaymentDate
    from dbo.Payments p
    inner join dbo.CreditPayments cp on cp.PaymentId = p.id
    where cp.CreditId = c.id
        and p.Way in (1, 2, 10)
) cp
outer apply
(
    select 
        p.DateCreated
        , p.Amount
    from dbo.Payments p
    inner join dbo.CreditPayments cp on cp.PaymentId = p.id
    where cp.CreditId = c.id
        and p.Way in (1, 2, 10)
    order by p.DateCreated
    for xml raw
) pl(plist)
outer apply
(
    select top 1 'Yes' as HadProlongations
    from dbo.ProlongCreditUnits pcu
    where pcu.CreditId = c.id
) pcu
outer apply
(
    select 
        count(distinct case when dsh.StatusType = 23 then 1 end) as ObjectionAnswered
        , count(distinct case when dsh.StatusType = 24 then 1 end) as ObjectionRejected
        , count(distinct case when dsh.StatusType = 8 then 1 end) as IsDead
        , count(distinct case when dsh.StatusType = 47 then 1 end) as IsBankrupt
        , min(case when dsh.StageType = 2 then dsh.DateCreated end) as CollectionStartDate
        , count(distinct case when ee.ExecutionEntitlement = 1 then 1 end) as ExecutionEntitlement
        , min(case when dsh.StageType = 4 then dsh.DateCreated end) as BailiffSentDate
        , min(case when dsh.StatusType in (26, 35, 36, 37) then dsh.DateCreated end) as DiscontinuanceDate
    from dbo.DebtorStateHistory dsh
    outer apply
    (
        select top 1 1 as ExecutionEntitlement
        from
        (
            values
            (21), (29), (30), (31), (32), (33), (35), (36), (37), (39)
            , (42), (45), (47), (48), (49), (54), (55), (56), (57)
        ) ds(DebtorState)
        where ds.DebtorState = dsh.StatusType
    ) ee
    where dsh.DebtorId = d.id
) dsh
outer apply
(
    select top 1 ebr.Label_en as BailiffResult
    from dbo.DebtorStateHistory br
    left join dbo.Enums ebr on ebr.Val = br.StatusType
        and ebr.Enum = 'DebtorStageStatus'
    where br.DebtorId = d.id
        and br.StageType = 4
    order by br.DateCreated desc
) br
outer apply
(
    select top 1 edr.Label_en as DiscontinuanceReason
    from dbo.DebtorStateHistory dr
    left join dbo.Enums edr on edr.Val = dr.StatusType
        and edr.Enum = 'DebtorStageStatus'
    where dr.DebtorId = d.id
        and dr.StatusType in (26, 35, 36, 37)
    order by dr.DateCreated
) dr
outer apply
(
    select top 1 
        ua.PostIndex as HomeAddressZip
        , ua.CityName as HomeAddressCity
    from dbo.UserAddresses ua
    inner join dbo.UserAddressesExtended uae on uae.UserAddressId = ua.Id
    where uae.UserAddressType = 2
        and uae.UserId = c.UserId
) ha
outer apply
(
    select top 1 
        ua.PostIndex as ResidenceZip
        , ua.CityName as ResidenceCity
        , uae.IsActive as ResidenceIsActive
    from dbo.UserAddresses ua
    inner join dbo.UserAddressesExtended uae on uae.UserAddressId = ua.Id
    where uae.UserAddressType = 3
        and uae.UserId = c.UserId
) ra
outer apply
(
    select top 1 
        ua.PostIndex as CorrespondenceZip
        , ua.CityName as CorrespondenceCity
    from dbo.UserAddresses ua
    inner join dbo.UserAddressesExtended uae on uae.UserAddressId = ua.Id
    where uae.UserAddressType = 1
        and uae.UserId = c.UserId
) ca
outer apply
(
    select top 1 up.Phone
    from dbo.UserPhones up
    where up.UserId = c.UserId
        and up.UserPhoneType = 3
) up
outer apply
(
    select
        max(dch.DateCreated) as LastCallDate
        , count(*) as CallsCount
    from dbo.DebtorContactHistory dch
    where dch.DebtorId = d.id
        and dch.ContactType = 4
) dch
where c.status in (3, 10)
    and datediff(d, os.OverdueStart, getdate()) > 89
    and isnull(cp.IsNeededEntry, 1) = 1
/
