select
    c.UserId as ClientId
    ,c.id as CreditId
    ,c.DogovorNumber as ContractNumber
    ,cast(dch.DateCreated as date) as AssignDate
    ,case
        when ua.AgentName is null
            and not (cast(dch.DateCreated as date) between '20170626' and '20170815')
        then
            case t.name
                when 'Lime' then N'ООО МФК Лайм-Займ'
                when 'Konga' then N'ООО МФК "Конга"'
                when 'Mango' then N'ООО МФК «МангоФинанс»'
            end
        when ua.AgentName is null
            and (cast(dch.DateCreated as date) between '20170626' and '20170815')
        then N'ООО "Коллекторское агенство "Барс"'
        else ua.AgentName
    end as AgentName
from dbo.Tariffs t, dbo.Credits c
inner join dbo.Debtors d on d.CreditId = c.id
inner join dbo.DebtorCollectorHistory dch on dch.DebtorId = d.id
inner join dbo.syn_CmsUsers u on u.UserId = dch.CollectorId
left join dbo.vw_LawyerReportUserAgent ua on ua.UserId = dch.CollectorId
where t.id = 2 
    and c.UserId =
    (
        select top 1 c.UserId
        from dbo.Debtors d
        inner join dbo.Credits c on c.id = d.CreditId
        order by newid()
    )

union all

select
    c.UserId as ClientId
    ,c.id as CreditId
    ,c.DogovorNumber as ContractNumber
    ,cast(dtc.TransferDate as date) as AssignDate
    ,case dtc.CessionId
        when 1 then N'ООО "Коллекторское агенство "Барс"'
        else N'ООО "СКГ"'
    end as AgentName
from dbo.DebtorTransferCession dtc
inner join dbo.Debtors d on d.id = dtc.DebtorId
inner join dbo.Credits c on c.id = d.CreditId
where dtc.CessionId in (1, 2)
    and c.UserId =
    (
        select top 1 c2.UserId
        from dbo.Debtors d2
        inner join dbo.Credits c2 on c2.id = d2.CreditId
        inner join dbo.DebtorTransferCession dtc on dtc.DebtorId = d2.id
        order by newid()
    )
order by AssignDate