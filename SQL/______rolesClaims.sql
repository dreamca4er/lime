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
            "EditClientsDetails",
            "ReadDebtorLastCollector"
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
            "EditClientsDetails"            ,
            "ReadDebtorLastCollector"
        ],
        "role": "Accountant"
    },
    {
        "claim": [
            "ReadDebtorInfo",
            "EditDebtorInfo",
            "ReadDebtorsList",
            "ReadDebtorCommentAuthor"
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
            "ReadCardsAndAccounts",
            "CanAddDebtorPhone",
            "ReadCollectorsDirectories",
            "EditCollectorsDirectories",
            "ReadDebtorLastCollector"
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
            "ReadDebtorsListOwnerFilter",
            "ReadDebtorCommentAuthor",
            "CanAddDebtorPhone",
            "ReadDebtorLastCollector"
        ],
        "role":"CollectorIncoming"
    },
    {
        "claim": [
            "ReadClientsInfo",
            "ReadClientsHead",
            "EditClientsHead",
            "ReadClientsDetails",
            "EditClientOperatorComment",
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
            "ReadClientsBlockMoneyWay",
            "ReadPromocode",
            "ReadTrafficSources",
            "ReadClientPromocodes",
            "ReadDebtorLastCollector",
            "EditClientsDetails"
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
            "ReadBlockingDirectory",
            "EditBlockingDirectory",
            "ReadBlacklistDirectory",
            "EditBlacklistDirectory",
            "ReadDirectoriesList",
            "ReadPromocode",
            "ReadTrafficSources",
            "ReadClientPromocodes",
            "EditShortTermTariffDirectory",
            "EditLongTermTariffDirectory",
            "ReadShortTermTariffDirectory",
            "ReadLongTermTariffDirectory",
            "ReadDebtorLastCollector"
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
            "ReadBlockingDirectory",
            "EditBlockingDirectory",
            "ReadBlacklistDirectory",
            "EditBlacklistDirectory",
            "ReadDirectoriesList",
            "ReadPromocode",
            "ReadTrafficSources",
            "ReadClientPromocodes",
            "EditShortTermTariffDirectory",
            "EditLongTermTariffDirectory",
            "ReadShortTermTariffDirectory",
            "ReadLongTermTariffDirectory",
            "ReadDebtorLastCollector"
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
            "ReadClientsMailSms",
            "ReadDebtorLastCollector"
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
            "ReadClientsMailSms",
            "ReadDebtorLastCollector"
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
            "ReadDebtorsListOwnerFilter",
            "EditClientsMailSms",
            "ReadDebtorLastCollector",
            "EditClientsDetails"
        ],
        "role": "Lawyer"
    },
    {
        "claim": [
            "ReadClientsDetails"
            ,"ReadClientsAggregateData"
            ,"ReadClientsHead"
            ,"ReadClientsUploadDocuments"
            ,"EditClientsUploadDocuments"
            ,"ReadClientsProduct"
            ,"ReadClientsProductList"
            ,"ReadClientsMailSms"
            ,"EditClientsMailSms"
            ,"ReadClientsNotificationBox"
            ,"EditClientsNotificationBox"
            ,"ReadClientsList"
            ,"ReadDebtorsList"
            ,"ReadDebtorInfo"
            ,"ReadClientsInfo"
            ,"EditClientsHead"
            ,"EditClientsDetails"
            ,"EditClientsInfo"

        ],
        "role": "RiskManager"
    },
    {
        "claim": [
            "ReadClientsList"
            ,"ReadClientsInfo"
            ,"EditClientsInfo"
            ,"ReadClientsHead"
            ,"ReadClientsDetails"
            ,"EditClientsDetails"
            ,"ReadClientsProduct"
            ,"ReadClientsNotificationBox"
            ,"ReadClientsComments"
            ,"ReadClientsUploadDocuments"
            ,"ReadClientsBlockMoneyWay"
            ,"ReadCardsAndAccounts"
            ,"ReadClientsBlock"
            ,"EditClientsBlock"
            ,"ReadClientsAggregateData"
            ,"ReadClientsMailSms"
            ,"ReadDebtorsList"
            ,"ReadDebtorInfo"
            ,"ReadClientsProductList"
            ,"EditClientsHead"
            ,"ReadDebtorsListOwnerFilter"
        ],
        "role": "RiskOperator"
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
            "EditBlacklistDirectory",
            "ReadDirectoriesList",
            "ReadDebtorLastCollector",
            "ReadCardsAndAccounts"
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
            "ReadClientsInfo",
            "ReadPromocode",
            "EditPromocode",
            "EditTrafficSources",
            "ReadTrafficSources",
            "ReadClientsProduct",
            "ReadClientPromocodes",
            "EditShortTermTariffDirectory",
            "EditLongTermTariffDirectory",
            "ReadShortTermTariffDirectory",
            "ReadLongTermTariffDirectory",
            "ReadDebtorLastCollector",
            "ReadLoyaltyProgram"
        ],
        "role": "HeadMarketer"
    },
    {
        "claim": [
            "ReadClientsHead",
            "ReadClientsList",
            "ReadClientsDetails",
            "ReadClientsInfo",
            "ReadPromocode",
            "EditPromocode",
            "EditTrafficSources",
            "ReadTrafficSources",
            "ReadClientsProduct",
            "ReadClientPromocodes",
            "ReadClientsProductList",
            "ReadDebtorLastCollector",
            "ReadLoyaltyProgram"
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
            