select
    uk.userid
    ,uk.lastname
    ,uk.firstname
    ,uk.fathername
    ,uk.mobilephone
    ,uk.emailaddress
    ,edu.Description as userStatus
from Bi.dbo.UsersLime uk
left join LimeZaim_Website.dbo.EnumDescriptions edu on edu.Value = uk.userStatus
    and edu.Name = 'UserStatusKind'
where uk.blockDate is null
    and uk.userStatus != 6
    and uk.IsFraud = 0
    and uk.IsDied = 0
    and not exists 
                (
                    select 1 from dbo.UsersMango um
                    where (um.Passport = uk.Passport or um.mobilephone = uk.mobilephone)
                        and (um.userStatus = 6 or um.blockDate is not null or um.IsDied = 1)
                )