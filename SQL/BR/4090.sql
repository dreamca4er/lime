drop table if exists #ch
;

select 
    ProjectClientId as ClientId 
    ,max(EquifaxRequestCreatedOn) as EquifaxRequestCreatedOn
into #ch
from cr.syn_EquifaxResponse er
group by ProjectClientId
;

create index IX_ch_ClientId on #ch(ClientId)
;

with Base as 
(
    select
        c.clientid
        ,c.LastName
        ,c.FirstName
        ,c.FatherName
        ,c.PhoneNumber
        ,iif(c.EmailConfirmed = 1, c.Email, null) as Email
        ,case 
            when st.IsLatest = 1
            or st.TariffStartEnd between dateadd(d, -30, cast(getdate() as date)) and cast(getdate() as date)
                and st.IsLatest = 0
            then st.TariffId
            else null
        end as STTariffId
        ,case 
            when st.IsLatest = 1
            or st.TariffStartEnd between dateadd(d, -30, cast(getdate() as date)) and cast(getdate() as date)
                and st.IsLatest = 0
            then st.IsLatest
            else null
        end as STIsLatest
        ,case 
            when lt.IsLatest = 1
            or lt.TariffStartEnd between dateadd(d, -30, cast(getdate() as date)) and cast(getdate() as date)
                and lt.IsLatest = 0
            then lt.TariffId
            else null
        end as LTTariffId
        ,case 
            when lt.IsLatest = 1
            or lt.TariffStartEnd between dateadd(d, -30, cast(getdate() as date)) and cast(getdate() as date)
                and lt.IsLatest = 0
            then lt.IsLatest
            else null
        end as LTIsLatest
    from Client.vw_client c
    outer apply
    (
        select top 1 
            ut.TariffId
            ,ut.TariffName
            ,d.TariffStart
            ,cast(dateadd(d, ut.ActivePeriod, d.TariffStart) as date) as TariffStartEnd
            ,ut.IsLatest
        from client.vw_TariffHistory ut
        outer apply
        (
            select max(dt) as TariffStart
            from (values (ut.CreatedOn), (ut.ModifiedOn)) as d(dt)
        ) d
        where ut.ClientId = c.clientid
            and ut.ProductType = 1
        order by d.TariffStart desc
    ) st
    outer apply
    (
        select top 1 
            ut.TariffId
            ,ut.TariffName
            ,d.TariffStart
            ,cast(dateadd(d, ut.ActivePeriod, d.TariffStart) as date) as TariffStartEnd
            ,ut.IsLatest
        from client.vw_TariffHistory ut
        outer apply
        (
            select max(dt) as TariffStart
            from (values (ut.CreatedOn), (ut.ModifiedOn)) as d(dt)
        ) d
        where ut.ClientId = c.clientid
            and ut.ProductType = 2
        order by d.TariffStart desc
    ) lt
    where c.status = 2
        and 
        (
            st.TariffStartEnd between dateadd(d, -30, cast(getdate() as date)) and cast(getdate() as date) and st.IsLatest = 0
            or
            lt.TariffStartEnd between dateadd(d, -30, cast(getdate() as date)) and cast(getdate() as date) and lt.IsLatest = 0
            or st.IsLatest = 1
            or lt.IsLatest = 1
        )
        and not exists
            (
                select 1 from prd.vw_product p
                where p.ClientId = c.clientid
                    and p.Status in (2, 3, 4, 7, 8)
            )
)

,allClients as 
(
    select 
        b.clientid
        ,b.LastName
        ,b.FirstName
        ,b.FatherName
        ,b.PhoneNumber
        ,b.Email
        ,stt.Name as STName
        ,b.STIsLatest
        ,ltt.Name as LTName
        ,b.LTIsLatest
        ,crr.*
        ,ch.EquifaxRequestCreatedOn
        ,st.PaidCnt as stPaidCnt  
        ,lt.PaidCnt as ltPaidCnt
        ,(select max(dt) from (values (st.LastDatePaid), (lt.LastDatePaid)) d(dt)) as LastDatePaid
        ,case 
            when st.LastStartedOn > lt.LastStartedOn or lt.LastStartedOn is null and st.LastStartedOn is not null then N'КЗ'
            when lt.LastStartedOn > st.LastStartedOn or st.LastStartedOn is null and lt.LastStartedOn is not null then N'ДЗ'
        end as LastTakenProductType
        ,isnull(ll.DisplayLevel, '0') as LoyaltyLevel
        ,ll.Discount
        ,iif(cul.CustomField1 is not null, N'Да', N'Нет') as STWasUpped
        ,iif(cul.CustomField2 is not null, N'Да', N'Нет') as LTWasUpped
    from Base b
    left join prd.ShortTermTariff stt on stt.Id = STTariffId
    left join prd.LongTermTariff ltt on ltt.Id = LTTariffId
    left join #ch ch on ch.ClientId = b.ClientId
    left join dbo.CustomListUsers cul on cul.ClientId = b.ClientId
        and cul.CustomlistID = 1084
    outer apply
    (
        select top 1 
            iif(isnull(crr.Score, 0) = 0, null, crr.CreatedOn) as CreatedOn
            ,nullif(crr.Score, 0) as Score
        from cr.CreditRobotResult crr
        where crr.ClientId = b.ClientId
        order by crr.CreatedOn desc
    ) crr
    outer apply
    (
        select
            count(*) as PaidCnt
            ,max(p.DatePaid) as LastDatePaid
            ,max(p.StartedOn) as LastStartedOn
        from prd.vw_product p
        where p.ClientId = b.ClientId
            and p.Status = 5
            and p.ProductType = 1
    ) st
    outer apply
    (
        select
            count(*) as PaidCnt
            ,max(p.DatePaid) as LastDatePaid
            ,max(p.StartedOn) as LastStartedOn
        from prd.vw_product p
        where p.ClientId = b.ClientId
            and p.Status = 5
            and p.ProductType = 2
    ) lt
    outer apply
    (
        select 
            ll.DisplayLevel
            ,1 - rf.Factor as Discount 
        from mkt.ClientReductionFactor crf
        inner join mkt.LoyaltyLevels ll on ll.Id = crf.ReductionFactorId
        inner join mkt.ReductionFactor rf on rf.id = crf.ReductionFactorId
        where crf.ClientId = b.ClientId
    ) as ll
    where 1=1
)


select *
from allClients c
where Score is not null