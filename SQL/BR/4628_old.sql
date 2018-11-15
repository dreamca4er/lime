set transaction isolation level read uncommitted
;

/*
    c.clientid
    ,c.fio
    ,c.IsFrauderChangedAt
    ,un.ClaimValue as IsFrauderChangedBy 
    ,h.name as RegionName
    ,p.Productid
    ,p.StartedOn
    ,p.Amount
    ,p.StatusName
    ,bapi.AccountNum
    ,b.Name as BankName
*/

select distinct
    uc.UserId
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,uc.IsFraudDateChanged
    ,u.UserName as IsFraudDateChangedBy
    ,uai.RegRegion
    ,c.id as Productid
    ,c.DateStarted
    ,c.Amount
    ,cs.Description as CreditStatus
    ,ba.AccountNum
    ,b.Name as BankName
from dbo.UserCards uc
inner join dbo.FrontendUsers fu on fu.Id = uc.UserId
inner join dbo.Credits c on c.UserId = uc.UserId
    and c.Way = -2
inner join dbo.Payments p on p.id = c.BorrowPaymentId
left join dbo.EnumDescriptions cs on cs.Value = c.Status
    and cs.Name = 'CreditStatus'
left join dbo.UserAdminInformation uai on uai.userid = uc.UserId
left join dbo.BankAccounts ba on ba.Id = p.BankAccountId
left join dbo.Banks b on b.id = ba.BankId
left join dbo.syn_CmsUsers u on u.userid = uc.IsFraudChangedByUserId
where uc.IsFraud = 1
    and uc.IsFraudDateChanged >= '20180101'
    and c.Status != 8
/

set transaction isolation level read uncommitted
;


select distinct
    uc.UserId
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
    ,uc.IsFraudDateChanged
    ,u.UserName as IsFraudDateChangedBy
    ,uai.RegRegion
    ,c.id as Productid
    ,c.DateStarted
    ,c.Amount
    ,cs.Description as CreditStatus
    ,p.CardNumber
from dbo.UserCards uc
inner join dbo.FrontendUsers fu on fu.Id = uc.UserId
inner join dbo.Credits c on c.UserId = uc.UserId
    and c.Way = -3
inner join dbo.Payments p on p.id = c.BorrowPaymentId
left join dbo.EnumDescriptions cs on cs.Value = c.Status
    and cs.Name = 'CreditStatus'
left join dbo.UserAdminInformation uai on uai.userid = uc.UserId
left join dbo.syn_CmsUsers u on u.userid = uc.IsFraudChangedByUserId
where uc.IsFraud = 1
    and uc.IsFraudDateChanged >= '20180101'
    and c.Status != 8