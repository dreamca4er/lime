drop table if exists #requests
;

select
    res.EquifaxRequestId
    , res.EquifaxResponseId
    , res.LocalClientId
    , res.ProjectName
into #requests
from wrh.vw_EquifaxResponse res
where res.EquifaxRequestCreatedOn >= dateadd(month, -5, getdate())
    and not exists 
    (
        select *
        from wrh.vw_EquifaxResponse res2
        where res2.LocalClientId = res.LocalClientId
            and res2.EquifaxRequestCreatedOn > res.EquifaxRequestCreatedOn
    )
    and not exists
    (
        select 1 from wrh.vw_EquifaxCreditInfo ci
        where ci.EquifaxResponseId = res.EquifaxResponseId
            and ci.CreditInfoType = 2
            and ci.DateOpen >= dateadd(month, -5, getdate())
    )
    and not exists
    (
        select 1 from wrh.vw_EquifaxCreditInfo ci
        where ci.EquifaxResponseId = res.EquifaxResponseId
            and ci.CreditInfoType = 2
            and ci.CreditType = 3 
            and ci.CreditActive != 0 -- Нет незакрытой ипотеки
    )
    and exists
    (
        select 1 from wrh.vw_EquifaxCreditInfo ci
        where ci.EquifaxResponseId = res.EquifaxResponseId
            and ci.CreditInfoType = 2
            and ci.CreditActive != 0
            and ci.OverdueLine like '[1-9B]%' -- Просрочка на последний момент
    )
;

/
drop table if exists #debt
;

select 
    r.EquifaxResponseId
    , r.LocalClientId
    , sum(case when ci.CreditType in (1, 2, 5, 14, 18, 19) then ci.SumDebit end) as Debt
into #debt
from #requests r
inner join wrh.vw_EquifaxCreditInfo ci on ci.EquifaxResponseId = r.EquifaxResponseId
where ci.CreditInfoType = 2
    and CreditActive != 0
    and ci.OverdueLine like '[1-9B]%'  -- С выгрузкой
group by r.EquifaxResponseId, r.LocalClientId
having sum(case when ci.CreditType in (1, 2, 5, 14, 18, 19) then ci.SumDebit end) >= 300000 -- Исключили кредитки, ипотеку
/

select d.*
into #fin
from #debt d
outer apply
(
    select top 1 1 as CrimeFound
    from wrh.CronosRequest creq
    inner join wrh.CronosResponse cres on cres.RequestId = creq.id
    outer apply openjson
    (
            '{"' + replace(replace(reverse(stuff(reverse(cres.ResponseVector), 1, 1, '')) 
                    , ',', '": "')
                    , ';', '", "') + '"}'
    ) js
    where creq.LocalClientId = d.LocalClientId
        and js."key" like '1.[147]' -- Судимости, розыск
        and cast(js.value as int) > 0
        and not exists
        (
            select 1 from wrh.CronosRequest creq2
            where creq2.LocalClientId = creq.LocalClientId
                and creq2.CreatedOn > creq.CreatedOn
        )
) cr
where isnull(cr.CrimeFound, 0) = 0
    and not exists
    (
        select 1
        from wrh.LocalClientProject lcp
        inner join "BOR-LIME-DB".Borneo.prd.vw_product lp on lp.ClientId = lcp.ProjectClientId
        where lcp.LocalClientId = d.LocalClientId
            and lcp.Project = 1
            and lp.status not in (1, 5)
    )
    and not exists
    (
        select 1
        from wrh.LocalClientProject lcp
        inner join Borneo.prd.vw_product lp on lp.ClientId = lcp.ProjectClientId
        where lcp.LocalClientId = d.LocalClientId
            and lcp.Project = 3
            and lp.status not in (1, 5)
    )
    and not exists
    (
        select 1
        from wrh.LocalClientProject lcp
        inner join wrh.LocalClient lc on lc.Id = lcp.LocalClientId
        inner join "KONGA-DB".LimeZaim_Website.dbo.UserCards uc on uc.Passport = lc.Passport
        inner join "KONGA-DB".LimeZaim_Website.dbo.Credits c on uc.UserId = c.UserId
        where lcp.LocalClientId = d.LocalClientId
            and c.Status in (1, 3) 
    )

/

select
    f.debt
    , f.LocalClientId
    , iif(lcp.Project = 1, N'Лайм', N'Манго') as Project
    , lcp.ProjectClientId as ClientId
    , isnull(cl.fio, cm.fio) as Fio
    , isnull(cl.PhoneNumber, cm.PhoneNumber) as PhoneNumber
    , isnull(cl.Email, cm.Email) as Email
    , isnull(cl.SexKind, cm.SexKind) as Gender
    , isnull(cl.substatusName, cm.substatusName) as Status
    , datediff(year, isnull(cl.BirthDate, cm.BirthDate), cast(getdate() as date)) 
    - iif(datepart(dy, isnull(cl.BirthDate, cm.BirthDate)) > datepart(dy, getdate()), 1, 0) as Age
from #fin f
inner join wrh.LocalClientProject lcp on lcp.LocalClientId = f.LocalClientId
left join "BOR-LIME-DB".Borneo.Client.address al on al.ClientId = lcp.ProjectClientId
    and lcp.Project = 1
    and al.AddressType = 1
left join Borneo.Client.address am on am.ClientId = lcp.ProjectClientId
    and lcp.Project = 3
    and am.AddressType = 1
left join "BOR-LIME-DB".Borneo.Client.vw_client cl on cl.CLientId = lcp.ProjectClientId
    and lcp.Project = 1
left join Borneo.Client.vw_client cm on cm.CLientId = lcp.ProjectClientId
    and lcp.Project = 3
where lcp.project in (1, 3)
    and isnull(al.RegionId, am.RegionId) = '54'
