drop table if exists #tmp2
;

with ph as 
(
    select 
        fu.id
        ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as fio
        ,cast(coalesce(p.PhoneNumber, fu.MobilePhone) as nvarchar(11)) as PhoneNumber
    from dbo.FrontendUsers fu
    outer apply
    (
        select top 1
            p.PhoneNumber
            ,p.Comment
            ,p.UseForAutoCalling
            ,p.DateCreated
        from dbo.Phones p
        where p.UserId = fu.id
            and p.PhoneType = 1
        order by p.id desc
    ) p
)

select 
    id as UserClientId
    ,phonenumber
    ,credCnt
    ,fio
    ,status + case when status = N'Заблокирован' then cast(bl.period as nvarchar(10)) else '' end as status
    ,case 
        when phonenumber = '2251335603' then 'test'
    end as Phonestate
into #tmp2
from ph
outer apply
(
    select top 1 ed.Description  as Status
    from dbo.UserStatusHistory ush
    left join dbo.EnumDescriptions ed on ed.Value = ush.Status
        and ed.name = 'UserStatusKind'
    where ush.UserId = ph.id
        and ush.islatest = 1
    order by ush.DateCreated desc
) stat
outer apply
(
    select top 1 ubh.Period
    from dbo.UserBlocksHistory ubh
    where ubh.UserId = ph.id
        and ubh.islatest = 1
    order by ubh.DateCreated desc
) bl
outer apply
(
    select count(*) as credCnt
    from dbo.Credits c
    where c.UserId = ph.id
        and c.Status not in (5, 8)
) c
where phonenumber in
        (
        select PhoneNumber
        from ph
        group by PhoneNumber
        having count(*) > 1
        )
    and (stat.Status !=  N'Удален' or stat.status is null)
GO

select
    phonenumber
    ,Phonestate
    ,count(distinct fio) as fiocnt
    ,replace((
        select 
            t1.UserClientId as id
            ,status
            ,fio
        from #tmp2 t1
        where t.phonenumber = t1.phonenumber
        for json auto), '"', '') as clients
    ,count(case when status = N'Удален' then 1 end) as Deleted
    ,count(case when status like N'Заблокирован%' then 1 end) as Blocked
    ,count(case when status = N'Регистрация' then 1 end) as Reg
    ,count(case when status like N'%Карта%' then 1 end) as card
    ,count(case when status = N'Есть кредит' then 1 end) as hasCredit
    ,count(case when status = N'Hет кредитов и есть тариф' then 1 end) as hastariff
    ,count(case when status is null then 1 end) as noStatus
    ,count(*) as total
    ,count(distinct case when status = N'Удален' and credCnt > 0 then UserClientId else null end) as DeletedCreds
    ,count(distinct case when status like N'Заблокирован%'  and credCnt > 0 then UserClientId else null  end) as BlockedCreds
    ,count(distinct case when status = N'Регистрация' and credCnt > 0 then UserClientId else null  end) as RegCreds
    ,count(distinct case when status like N'%Карта%' and credCnt > 0 then UserClientId else null  end) as cardCreds
    ,count(distinct case when status = N'Есть кредит' and credCnt > 0 then UserClientId else null  end) as hasCreditCreds
    ,count(distinct case when status = N'Hет кредитов и есть тариф' and credCnt > 0 then UserClientId else null  end) as hastariffCreds
    ,count(distinct case when status is null and credCnt > 0 then UserClientId else null  end) as noStatusCreds
    ,sum(credCnt) as totalCreds
    ,case 
        when phonenumber not like '9' + replicate('[0-9]', 9)
        then 'bad phone'
        when sum(credCnt) > 0
        then 'had creds'    -- Берем учетку, на который эти кредиты были
        when count(case when status like N'Заблокирован%' then 1 end) > 0
        then 'has block'    -- Берем последнюю (по id) заблоченную учетку 
        when count(case when status = N'Hет кредитов и есть тариф' then 1 end) > 0
        then 'has tariff'   -- Берем учетку, где Есть тариф
        else 'has reg or card'  -- Берем любую учетку по последнему id, в конце выкинем их в статус Регистрация
    end as type
from #tmp2 t
group by phonenumber, Phonestate
having count(case when status != N'Удален' then 1 end) > 1
    and count(*) > 1
