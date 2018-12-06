drop table if exists #ca
    ;
    
    select *
    into #ca
    from
    (
        select
            c.UserId as ClientId
            ,c.id as CreditId
            ,c.DogovorNumber as ContractNumber
            ,cast(ca.CollectorAssignStart as date) as AssignDate
            ,cast(ca.CollectorAssignEnd as date) as UnassignDate
            ,case
                when ua.AgentName is null
                    and not (cast(ca.CollectorAssignStart as date) between '20170626' and '20170815')
                then
                    case t.name
                        when 'Lime' then N'ООО МФК "Лайм-Займ"'
                        when 'Konga' then N'ООО МФК "Конга"'
                        when 'Mango' then N'ООО МФК «МангоФинанс»'
                    end
                when ua.AgentName is null
                    and (cast(ca.CollectorAssignStart as date) between '20170626' and '20170815')
                    and t.name = 'Lime'
                then N'ООО "Коллекторское агенство "Барс"'
                when ua.AgentName is null
                    and (cast(ca.CollectorAssignStart as date) between '20170626' and '20170815')
                then 
                    case t.name
                        when 'Konga' then N'ООО МФК "Конга"'
                        when 'Mango' then N'ООО МФК «МангоФинанс»'
                    end
                else ua.AgentName
            end as AgentName
            ,0 as IsCession
            ,ca.CollectorId
            ,ca.OverdueStart
            ,us.loginname as CollectorLogin
            ,us.UserName as CollectorName
            ,case 
                when u.username = N'коллектор 1-7' then 'A'
                else cg.CollectorGroup
            end as CollectorGroup
        from Limezaim_website.dbo.Tariffs t, Limezaim_website.dbo.Credits c
        inner join Limezaim_website.dbo.tf_getCollectorAssigns('19000101', getdate(), 0) ca on ca.CreditId = c.id
        inner join CmsContent_LimeZaim.dbo.Users u on u.UserId = ca.CollectorId
        left join Limezaim_website.dbo.vw_LawyerReportUserAgent ua on ua.UserId = ca.CollectorId
        left join syn_CmsUsers us on us.userid = ca.CollectorId
        outer apply
        (
            select top 1 case when ar.name like 'Collector[12]' then 'B' else 'C' end as CollectorGroup
            from LimeZaim_Website.dbo.AclAdminRoles aar
            inner join LimeZaim_Website.dbo.AclRoles ar on ar.id = aar.AclRoleId
            where aar.AdminId = us.userid
                and ar.name like 'Collector[123]'
        ) cg
        where t.id = 2
            
        union all
        
        select
            c.UserId as ClientId
            ,c.id as CreditId
            ,c.DogovorNumber as ContractNumber
            ,cast(dtc.TransferDate as date) as AssignDate
            ,null as UnAssignDate
            ,case dtc.CessionId
                when 1 then N'ООО "Коллекторское агенство "Барс"'
                else N'ООО "СКГ"'
            end as AgentName
            ,1 as IsCession
            ,null as CollectorId
            ,null as OverdueStart
            ,null as CollectorLogin
            ,ces.Name
            ,null
        from Limezaim_website.dbo.DebtorTransferCession dtc
        inner join Limezaim_website.dbo.Debtors d on d.id = dtc.DebtorId
        inner join Limezaim_website.dbo.Credits c on c.id = d.CreditId
        left join Limezaim_website.dbo.Cessions ces on ces.Id = dtc.CessionId
        where dtc.CessionId in (1, 2)
    ) ca
    ;
    
    create index IX_ca_CreditId_AssignDate on #ca(CreditId, AssignDate)
    
    drop table if exists #l
;

    with l as 
    (
        select *
            ,min(case when IsCession = 1 then AssignDate end) over (partition by CreditId) as CessionDate
            ,lag(AgentName) over (partition by creditid order by AssignDate) as PreviousAgentName
            ,lead(AgentName) over (partition by creditid order by AssignDate) as NextAgentName
        from #ca ca
        where ca.IsCession = 1
            or ca.IsCession = 0
                and not exists 
                    (
                        select 1 from #ca ca2
                        where ca.CreditId = ca2.CreditId
                            and ca2.AssignDate < ca.AssignDate
                            and ca2.IsCession = 1
                    )
    )
    select *
    into #l
    from l
    
    drop table if exists dbo.AllCA
    ;
    
    with ud as 
    (
        select
            ClientId
            ,CreditId
            ,ContractNumber
            ,AssignDate
            ,AgentName
            ,IsCession
            ,CollectorId
            ,OverdueStart
            ,CessionDate
            ,PreviousAgentName
            ,NextAgentName
            ,case 
                when IsCession = 0 
                then (select min(dt) from (values (UnassignDate), (CessionDate)) d(dt))
            end as UnassignDate
            ,CollectorLogin
            ,CollectorName
            ,CollectorGroup
        from #l l
    )
    
    select
        ClientId
        ,CreditId
        ,ContractNumber
        ,CollectorId
        ,CollectorLogin
        ,CollectorName
        ,CollectorGroup
        ,cast(AgentName as nvarchar(100)) as AgentName
        ,IsCession
        ,OverdueStart
        ,AssignDate
        ,UnassignDate
        ,CessionDate
        ,cast(PreviousAgentName as nvarchar(100)) as PreviousAgentName 
        ,cast(NextAgentName as nvarchar(100)) as NextAgentName
    into dbo.AllCA
    from ud