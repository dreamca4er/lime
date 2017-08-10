select
    uc.UserId
    ,IsFraud
    ,IsFraudDateChanged
    ,u.username
    ,case 
        when exists 
    (
        select 1 from Debtors d
        inner join Credits c on c.Id = d.CreditId
        where c.UserId = uc.UserId
            and d.Status != 3
    )
         then 1
         else 0
    end as isDebtor
from dbo.UserCards uc
inner join dbo.syn_CmsUsers u on u.userid = uc.IsFraudChangedByUserId
where uc.IsFraudDateChanged >= '20170731'
