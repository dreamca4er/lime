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
            and (ci.DateOpen > dateadd(month, -5, getdate()) or ci.CreditType = 3 and ci.CreditActive != 0) -- Нет незакрытой ипотеки
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
    and ci.OverdueLine not like '[-]%'  -- С выгрузкой
group by r.EquifaxResponseId, r.LocalClientId
having sum(case when ci.CreditType in (1, 2, 5, 14, 18, 19) then ci.SumDebit end) >= 300000 -- Исключили кредитки, ипотеку
/

select d.*
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
