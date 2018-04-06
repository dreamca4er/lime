use Borneo
;

drop table if exists #tmpRoles
;

declare @roles nvarchar(max) = 
    '[
    {
        "claim": [
            "ReadAccountsList",
            "EditAccountsList",
            "ReadClientsInfo",
            "ReadClientsList",
            "ReadClientsUploadDocuments",
            "EditClientsUploadDocuments",
            "ReadClientsProduct",
            "EditClientsProduct",
            "ReadClientsProductList",
            "ReadClientsDetails",
            "EditClientsDetails"
        ],
        "role": "HeadAccountant"
    },
    {
        "claim": [
            "ReadAccountsList",
            "Void",
            "ReadClientsInfo",
            "ReadClientsList",
            "ReadClientsUploadDocuments",
            "EditClientsUploadDocuments",
            "ReadClientsProduct",
            "EditClientsProduct",
            "ReadClientsProductList",
            "ReadClientsDetails",
            "EditClientsDetails"            
        ],
        "role": "Accountant"
    },
    {
        "claim": [
            "ReadDebtorInfo",
            "EditDebtorInfo",
            "ReadDebtorsList"
        ],
        "role": "Collector"
    },
    {
        "claim": [
            "ReadDebtorInfo",
            "EditDebtorInfo",
            "ReadDebtorsList",
            "EditDebtorsList",
            "ReadClientsList",
            "ReadClientsHead",
            "ReadClientsDetails",
            "EditClientsDetails",
            "ReadClientsNotificationBox",
            "ReadClientsUploadDocuments",
            "EditClientsUploadDocuments",
            "ReadClientsInfo",
            "ReadDebtorsListOwnerFilter",
            "EditDebtorOwner",
            "ReadDebtorOwner",
            "ReadClientsProduct",
            "ReadClientsProductList",
            "ReadCardsAndAccounts"
        ],
        "role": "HeadCollector"
    },
    {
        "claim": [
            "ReadDebtorInfo",
            "EditDebtorInfo",
            "ReadDebtorsList",
            "EditClientsUploadDocuments",
            "ReadClientsList",
            "ReadClientsInfo",
            "ReadClientsUploadDocuments",
            "ReadDebtorsListOwnerFilter"
        ],
        "role":"CollectorIncoming"
    },
    {
        "claim": [
            "ReadClientsInfo",
            "ReadClientsHead",
            "EditClientsHead",
            "ReadClientsDetails",
            "EditClientsDetails",
            "ReadClientsProduct",
            "ReadClientsProductList",
            "ReadClientsNotificationBox",
            "EditClientsNotificationBox",
            "ReadClientsList",
            "ReadClientsUploadDocuments",
            "EditClientsUploadDocuments",
            "ReadClientsMailSms",
            "ReadClientsAggregateData",
            "ReadCardsAndAccounts",
            "ReadClientsBlockMoneyWay"
        ],
        "role": "Operators"
    },
    {
        "claim": [
            "ReadClientsBlockMoneyWay",
            "EditClientsBlockMoneyWay",
            "ReadClientsDetails",
            "EditClientsDetails",
            "ReadClientsProduct",
            "ReadClientsProductList",
            "EditClientsProduct",
            "ReadClientsHead",
            "EditClientsHead",
            "ReadClientsUploadDocuments",
            "EditClientsUploadDocuments",
            "ReadClientsComments",
            "EditClientsComments",
            "ReadClientsList",
            "ReadClientsNotificationBox",
            "ReadCardsAndAccounts",
            "ReadClientsInfo",
            "ReadClientsBlock",
            "EditClientsBlock",
            "ReadClientsMailSms",
            "EditClientsMailSms",
            "ReadClientsAggregateData",
            "ReadDirectoriesList",
            "ReadBlockingDirectory",
            "EditBlockingDirectory",
            "ReadBlacklistDirectory",
            "EditBlacklistDirectory"
        ],
        "role": "OperatorFullAccess"
    },
    {
        "claim": [
            "ReadClientsBlockMoneyWay",
            "EditClientsBlockMoneyWay",
            "ReadClientsDetails",
            "EditClientsDetails",
            "ReadClientsProduct",
            "ReadClientsProductList",
            "EditClientsProduct",
            "ReadClientsHead",
            "EditClientsHead",
            "ReadClientsUploadDocuments",
            "EditClientsUploadDocuments",
            "ReadClientsList",
            "ReadClientsNotificationBox",
            "EditClientsNotificationBox",
            "ReadCardsAndAccounts",
            "ReadClientsInfo",
            "ReadClientsBlock",
            "EditClientsBlock",
            "ReadClientsMailSms",
            "EditClientsMailSms",
            "ReadClientsAggregateData",
            "ReadDirectoriesList",
            "ReadBlockingDirectory",
            "EditBlockingDirectory",
            "ReadBlacklistDirectory",
            "EditBlacklistDirectory"
        ],
        "role": "SeniorOperator"
    },
    {
        "claim": [
            "ReadClientsBlock",
            "EditClientsBlock",
            "ReadClientsDetails",
            "EditClientsDetails",
            "ReadClientsHead",
            "EditClientsHead",
            "ReadClientsUploadDocuments",
            "EditClientsUploadDocuments",
            "ReadClientsList",
            "ReadCardsAndAccounts",
            "ReadClientsInfo",
            "ReadClientsAggregateData",
            "EditClientsBlockMoneyWay",
            "ReadClientsBlockMoneyWay",
            "ReadClientsProduct",
            "ReadClientsProductList",
            "ReadClientsMailSms"
        ],
        "role": "Verificators"
    },
    {
        "claim": [
            "ReadClientsDetails",
            "EditClientsDetails",
            "ReadClientsHead",
            "EditClientsHead",
            "ReadClientsUploadDocuments",
            "EditClientsUploadDocuments",
            "ReadClientsList",
            "ReadClientsNotificationBox",
            "EditClientsNotificationBox",
            "ReadCardsAndAccounts",
            "ReadClientsInfo",
            "ReadClientsProduct",
            "ReadClientsProductList",
            "ReadClientsMailSms"
        ],
        "role": "HeadVerificator"
    },
    {
        "claim": [
            "ReadClientsDetails",
            "ReadClientsAggregateData",
            "ReadClientsUploadDocuments",
            "EditClientsUploadDocuments",
            "ReadClientsProduct",
            "ReadClientsMailSms",
            "ReadClientsNotificationBox",
            "ReadClientsList",
            "ReadDebtorsList",
            "ReadDebtorInfo",
            "ReadClientsInfo",
            "ReadClientsProductList",
            "ReadClientsHead",
            "EditClientsHead",
            "ReadDebtorsListOwnerFilter"
        ],
        "role": "Lawyer"
    },
    {
        "claim": [
            "ReadClientsDetails",
            "ReadClientsAggregateData",
            "ReadClientsUploadDocuments",
            "EditClientsUploadDocuments",
            "ReadClientsProduct",
            "ReadClientsMailSms",
            "EditClientsMailSms",
            "ReadClientsNotificationBox",
            "EditClientsNotificationBox",
            "ReadClientsList",
            "ReadDebtorsList",
            "ReadDebtorInfo",
            "ReadClientsInfo",
            "ReadClientsProductList",
            "ReadClientsHead",
            "EditClientsHead",
            "ReadDebtorsListOwnerFilter"
        ],
        "role": "RiskManager"
    },
    {
        "claim": [
            "ReadClientsDetails",
            "ReadClientsAggregateData",
            "ReadClientsUploadDocuments",
            "EditClientsUploadDocuments",
            "ReadClientsProduct",
            "ReadClientsMailSms",
            "ReadClientsNotificationBox",
            "ReadClientsList",
            "ReadDebtorsList",
            "ReadDebtorInfo",
            "ReadClientsInfo",
            "ReadClientsProductList",
            "ReadClientsHead",
            "EditClientsHead",
            "ReadBlacklistDirectory",
            "EditBlacklistDirectory"
        ],
        "role": "PODFT"
    },
    {
        "claim": [
            "FullAccess",
            "Void"
        ],
        "role": "admin"
    },
    {
        "claim": [
            "ReadClientsDetails",
            "ReadClientsHead",
            "ReadClientsList",
            "ReadClientsInfo"
        ],
        "role": "HeadMarketer"
    },
    {
        "claim": [
            "ReadClientsHead",
            "ReadClientsList",
            "ReadClientsDetails",
            "ReadClientsInfo"
        ],
        "role": "Marketer"
    },
    {
        "claim": [
            "ReadUsersList",
            "EditUsersList"
        ],
        "role": "Administrations"
    },
    {
        "claim": [
            "Void",
            "Void"
        ],
        "role": "User"
    },
    {
        "claim": [
            "Void",
            "Void"
        ],
        "role": "passwordChanger"
    },
    {
        "claim": [
            "Void",
            "Void"
        ],
        "role": "client"
    },
    {
        "claim": [
            "Void",
            "Void"
        ],
        "role": "stsUserRemover"
    },
    {
        "claim": [
            "Void",
            "Void"
        ],
        "role": "stsEditor"
    }
]'
;

update r
set name = 'SeniorOperator'
from sts.roles r
where name = 'HeadOperator'
;

update ur
set
    ur.RoleId = rh.Id
from sts.roles rH, sts.UserRoles ur
inner join sts.Roles r on r.Id = ur.RoleId
where r.name = 'LeadCollector'
    and rh.name = 'HeadCollector'
;


with roles as 
(
    select
        a."key" as roleId
        ,b."key"
        ,b."value"
    from openjson(@roles) a
    cross apply
    (
        select *
        from openjson(a.value)
    ) b
)

,claims as 
(
    select
        r.roleId
        ,rc.value as claimName
    from roles r
    cross apply
    (
        select *
        from openjson(r."value")
        where r."key" = 'claim'
    ) rc
    where r."key" = 'claim'
)

select 
   r."value" as roleName
   ,c.claimName
into #tmpRoles
from roles r
inner join claims c on r.roleId = c.roleId
where r."key" = 'role'
;

insert into sts.Roles
(
    Name, id
)
select *, newid()
from
(
    select distinct roleName
    from #tmpRoles tr
    where not exists
                (
                    select 1 from sts.Roles r
                    where tr.roleName = r.Name
                )
) a
;

insert into sts.RoleClaims
(
    Value, RoleId
)
select 
    tr.claimName
    ,r.Id
from #tmpRoles tr
inner join sts.Roles r on r.Name = tr.roleName
where not exists 
            (
                select 1 from sts.RoleClaims rc
                where rc.RoleId = r.Id
                    and rc.Value = tr.claimName
            )
;


delete r --select r.* 
from sts.Roles r
where not exists
            (
                select 1 from #tmpRoles t
                where t.roleName = r.Name
            )
;

delete rc -- select r.Name, rc.Value as claimName
from sts.Roles r
inner join sts.RoleClaims rc on rc.RoleId = r.Id
where not exists 
            (
                select 1 from #tmpRoles t
                where t.roleName = r.Name
                    and rc.Value = t.claimName
            )