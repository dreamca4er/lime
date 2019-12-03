CREATE PROCEDURE [rr].[sp_GetTemplates] as 
begin
    insert #Templates
    select *
        , row_number() over (partition by left(Id, 2)
                                order by GlobalSortOrder, LocalSortOrder) as TemplateIndex
    from
    (
        -- Для отображения достаточно конкретного выбранного ответа
        select
            t.Id
            , t.TemplateBody
            , t.GlobalSortOrder
            , t.LocalSortOrder
        from rr.Templates t
        where try_cast(json_value(t.ShowCondition, '$.ResponseId') as int) in (select r.id from #Responses r)
        
        union
        
        -- Для отображения необходимо выбрать несколько ответов
        select
            t.Id
            , t.TemplateBody
            , t.GlobalSortOrder
            , t.LocalSortOrder
        from rr.Templates t
        where json_query(t.ShowCondition, '$.ResponseId.and') is not null
            and not exists
            (
                select 1 
                from openjson(t.ShowCondition, '$.ResponseId.and') j
                left join #Responses r on r.id = j.value 
                where r.id is null
            )
    ) a
end
GO
CREATE PROCEDURE [rr].[sp_Template020100] as 
begin
    declare 
        @ClientId int = (select top 1 ClientId from #Contracts)
        , @ClientName nvarchar(100)
        , @ClientBirthday nvarchar(10)
    ;
    
    select
        @ClientName = c.Fio
        , @ClientBirthday = format(c.BirthDate, 'dd.MM.yyyy')
    from client.vw_Client c
    where c.ClientId = @ClientId
    ;
    
    insert #ReportMainPart
    (
        Id,TemplateBody,GlobalSortOrder,LocalSortOrder
    )
    select
        t.Id
        , replace(replace(t.TemplateBody
                , '{{ClientName}}', @ClientName)
                , '{{ClientBirthday}}', @ClientBirthday) as TemplateBody
        , GlobalSortOrder
        , LocalSortOrder
    from #Templates t
    where t.id = '020100'
end
GO
CREATE PROCEDURE [rr].[sp_Template020200] as
begin
    insert #ReportMainPart
    (
        Id,TemplateBody,GlobalSortOrder,IntermediateSortOrder,LocalSortOrder
    )
    select
        t.Id
        ,replace(replace(replace(t.TemplateBody
                , '{{ContractNumber}}', c.ContractNumber)
                , '{{ContractDate}}', format(c.CreatedOn, 'dd.MM.yyyy'))
                , '{{ContractState}}', N'исполнены') as TemplateBody
        , t.GlobalSortOrder
        , format(c.CreatedOn, 'yyyyMMdd') as IntermediateSortOrder
        , t.LocalSortOrder
    from #Contracts c, #Templates t
    where t.Id = '020200'
        and c.DatePaid is not null
        and exists
        (
            select 1 from #Contracts c2
            where c2.CreatedOn > c.CreatedOn 
        )
end
GO
CREATE PROCEDURE [rr].[sp_Template020300] as
begin

    insert #ReportMainPart
    (
        Id,TemplateBody,GlobalSortOrder,IntermediateSortOrder,LocalSortOrder
    )
    select
        t.Id
        ,replace(replace(replace(t.TemplateBody
                , '{{ActiveContractNumber}}', c.ContractNumber)
                , '{{ActiveContractDate}}', format(c.CreatedOn, 'dd.MM.yyyy'))
                , '{{ActiveContractState}}', s.ActiveContractState) as TemplateBody
        , t.GlobalSortOrder
        , format(c.CreatedOn, 'yyyyMMdd') as IntermediateSortOrder
        , t.LocalSortOrder
    from #Templates t, #Contracts c
    outer apply
    (
        select
            case 
                when c.IsOldProduct = 1 then N'отсутствуют'
                when c.NewSystemStatus = 6 then N'отсутствуют'
                when c.NewSystemStatus = 5 then N'исполнены'
                else N'исполняются'
            end as ActiveContractState
    ) s
    where t.Id = '020300'
        and c.DatePaid is null
end
GO
CREATE PROCEDURE [rr].[sp_Template040100] as 
begin
    with c as 
    (
        select
            cast(c.ContractNumber as nvarchar(10)) as ContractNumber
            , c.CreatedOn
        from #Contracts c
        where c.CreatedOn >= '20170101' 
            and c.CreatedOn < '20170601'
    )
    
    ,cl(ContractsList) as 
    (
        select
            N', № ' + c.ContractNumber
                + N' от ' + format(c.CreatedOn, N'dd.MM.yyyy г.') as 'text()'
        from c
        order by c.CreatedOn
        for xml path('')
    )

    insert #ReportMainPart
    (
        Id,TemplateBody,GlobalSortOrder,IntermediateSortOrder,LocalSortOrder
    )
    select
        t.Id
        , replace(t.TemplateBody, '{{ContractsList}}', stuff(cl.ContractsList, 1, 2, '')) as TemplateBody
        , t.GlobalSortOrder
        , (select format(min(c.CreatedOn), 'yyyyMMdd') from c) as IntermediateSortOrder
        , t.LocalSortOrder
    from #Templates t, cl
    where t.id = '040100'
end
GO
CREATE PROCEDURE [rr].[sp_Template040200] as 
begin
    with c as 
    (
        select
            cast(c.ContractNumber as nvarchar(10)) as ContractNumber
            , c.CreatedOn
        from #Contracts c
        where c.CreatedOn >= '20170601' 
            and c.CreatedOn < '20191031'
    )
    
    ,cl(ContractsList) as 
    (
        select
            N', № ' + c.ContractNumber
                + N' от ' + format(c.CreatedOn, N'dd.MM.yyyy г.') as 'text()'
        from c
        order by c.CreatedOn
        for xml path('')
    )

    insert #ReportMainPart
    (
        Id,TemplateBody,GlobalSortOrder,IntermediateSortOrder,LocalSortOrder
    )
    select
        t.Id
        , replace(t.TemplateBody, '{{ContractsList}}', stuff(cl.ContractsList, 1, 2, '')) as TemplateBody
        , t.GlobalSortOrder
        , (select format(min(c.CreatedOn), 'yyyyMMdd') from c) as IntermediateSortOrder
        , t.LocalSortOrder
    from #Templates t, cl
    where t.id = '040200'
end
GO
CREATE PROCEDURE [rr].[sp_Template040300] as 
begin
    with c as 
    (
        select
            cast(c.ContractNumber as nvarchar(10)) as ContractNumber
            , c.CreatedOn
        from #Contracts c
        where c.CreatedOn >= '20191031' 
    )
    
    ,cl(ContractsList) as 
    (
        select
            N', № ' + c.ContractNumber
                + N' от ' + format(c.CreatedOn, N'dd.MM.yyyy г.') as 'text()'
        from c
        order by c.CreatedOn
        for xml path('')
    )

    insert #ReportMainPart
    (
        Id,TemplateBody,GlobalSortOrder,IntermediateSortOrder,LocalSortOrder
    )
    select
        t.Id
        , replace(t.TemplateBody, '{{ContractsList}}', stuff(cl.ContractsList, 1, 2, '')) as TemplateBody
        , t.GlobalSortOrder
        , (select format(min(c.CreatedOn), 'yyyyMMdd') from c) as IntermediateSortOrder
        , t.LocalSortOrder
    from #Templates t, cl
    where t.id = '040300'
end
GO
CREATE PROCEDURE [rr].[sp_Template040400] as 
begin
    insert into #ReportMainPart
    (
        Id,TemplateBody,GlobalSortOrder,LocalSortOrder
    )
    select
        t.Id
        , t.TemplateBody
        , t.GlobalSortOrder
        , t.LocalSortOrder
    from #Templates t
    where exists
        (
            select 1 from #ReportMainPart mp
            where mp.id in ('040100','040200','040300')
        )
        and t.id = '040400'
end
GO
CREATE PROCEDURE [rr].[sp_Template050100] as 
begin
    insert into #ReportMainPart
    (
        Id,TemplateBody,GlobalSortOrder,LocalSortOrder
    )
    select
        t.Id
        , replace(t.TemplateBody
            , '{{ProlongationsList}}', stuff(Prolongations, 1, 1, '')) as TemplateBody
        , t.GlobalSortOrder
        , t.LocalSortOrder
    from #Templates t,
    (
        select
            char(10) 
            + N'№ ' + cast(c.ContractNumber as nvarchar(10))
            + format(c.CreatedOn, N' от dd.MM.yyyy г. ')
            + stuff(p.Prolongations, 1, 2, '') as 'text()'
        from #Contracts c
        outer apply
        (
            select 
                format(op.StartedOn, N', продлялся dd.MM.yyyy г. на ')
                + cast(op.Period as nvarchar(5)) + N' дней' as 'text()'
            from bi.OldProlongations op
            where op.ProductId = c.ProductId 
            for xml path('')
        ) p(Prolongations)
        where Prolongations is not null
        for xml path('')
    ) x(Prolongations)
    where t.Id = '050100'
end
GO
CREATE PROCEDURE [rr].[sp_Template050201] as
begin
    insert into #ReportMainPart
    (
        Id,TemplateBody,GlobalSortOrder,LocalSortOrder
    )
    select
        t.Id
        , t.TemplateBody
        , t.GlobalSortOrder
        , t.LocalSortOrder
    from #Templates t
    where t.Id = '050201'
        and exists
        (
        
            select top 1 1
            from #Contracts c
            left join prd.ShortTermProlongation p on c.ProductId = p.ProductId
                and p.StartedOn >= '20180225'
                and p.IsActive = 1
            left join prd.LongTermProlongation lp on c.ProductId = lp.ProductId
                and lp.StartedOn >= '20180225'
                and lp.IsActive = 1
            where isnull(p.id, lp.id) is not null
        )
end
GO
CREATE PROCEDURE [rr].[sp_Template050202] as 
begin
    with cdm as 
    (
        select distinct
            c.ContractNumber
            , cast(cdm.CreatedOn as date) as Date
        from doc.ClientDocumentMetadata cdm
        inner join #Contracts c on cdm.ContractNumber = c.ContractNumberWithZeros
        where cdm.CreatedOn >= '20180225'
            and cdm.DocumentType in (105, 106, 107, 701, 702)
            and cdm.IsDeleted = 0
    )

    insert into #ReportMainPart
    (
        Id,TemplateBody,GlobalSortOrder,IntermediateSortOrder,LocalSortOrder
    )
    select
        t.Id
        , replace(replace(replace(t.TemplateBody
            , '{{ContractNumber}}', c.ContractNumber)
            , '{{ContractDate}}', format(c.CreatedOn, 'dd.MM.yyyy'))
            , '{{AgreementList}}', stuff(d.AgreementList, 1, 1, '')) as TemplateBody
        , t.GlobalSortOrder
        , format(c.CreatedOn, 'yyyyMMdd') as IntermediateSortOrder
        , t.LocalSortOrder
    from #Contracts c
    cross apply #Templates t
    cross apply
    (
        select 
            char(10)
            + cast(row_number() over (order by cdm.Date) as nvarchar(5))
            + format(cdm.Date, N'. Соглашение от dd.MM.yyyy г.;') as 'text()'
        from cdm
        where cdm.ContractNumber = c.ContractNumberWithZeros
        order by cdm.Date
        for xml path('')
    ) d(AgreementList)
    where t.Id = '050202'
        and d.AgreementList is not null
end
GO
CREATE PROCEDURE [rr].[sp_Template050203] as 
begin
    insert into #ReportMainPart
    (
        Id,TemplateBody,GlobalSortOrder,LocalSortOrder
    )
    select
        t.Id
        , t.TemplateBody
        , t.GlobalSortOrder
        , t.LocalSortOrder
    from #Templates t
    where exists
        (
            select 1 from #ReportMainPart mp
            where mp.id in ('05021','05022')
        )
        and t.id = '050203'
end
GO
CREATE PROCEDURE [rr].[sp_Template050300] as 
begin
    insert into #ReportMainPart
    (
        Id,TemplateBody,GlobalSortOrder,LocalSortOrder
    )
    select
        t.Id
        , t.TemplateBody
        , t.GlobalSortOrder
        , t.LocalSortOrder
    from #Templates t
    where not exists
        (
            select 1 from #ReportMainPart mp
            where mp.id in ('050201','050202','050203')
        )
        and t.id = '050300'
end
GO
CREATE PROCEDURE [rr].[sp_Template050400] as 
begin
    insert into #ReportMainPart
    (
        Id,TemplateBody,GlobalSortOrder,LocalSortOrder
    )
    select
        t.Id
        , replace(t.TemplateBody
            , '{{InsurancesList}}', stuff(i.InsurancesList, 1, 2, '')) as TemplateBody
        , t.GlobalSortOrder
        , t.LocalSortOrder
    from #Templates t
    outer apply
    (
        select
            N', № ' + i.ContractNumber + format(i.CreatedOn, N' от dd.MM.yyyy г.') as 'text()'
        from #Contracts c
        inner join prd.vw_Insurance i on i.LinkedLoanId = c.ProductId
            and i.Status != 1
        for xml path('')
    ) i(InsurancesList)
    where t.id = '050400'
end
GO
CREATE PROCEDURE [rr].[sp_Template070100] as 
begin
    with cc as 
    (
        select distinct DateFrom, ConditionsName as CommonConditionsName
        from #Contracts c
        outer apply
        (
            select top 1 cc.ConditionsName, DateFrom
            from rr.CommonConditions cc
            where ConditionsType = 1
                and cc.DateFrom < c.CreatedOn
            order by cc.DateFrom desc
        ) cc
    )

    insert into #ReportMainPart
    (
        Id,TemplateBody,GlobalSortOrder,LocalSortOrder
    )
    select
        t.Id
        , cast(t.TemplateIndex as nvarchar(5)) + '.'
        + cast(row_number() over (order by cc.DateFrom) as nvarchar(5)) + ' '
        + replace(t.TemplateBody, '{{CommonConditionsName}}', CommonConditionsName)
         as TemplateBody
        , t.GlobalSortOrder
        , t.LocalSortOrder
    from cc, #Templates t
    where t.Id = '070100'
end
GO
