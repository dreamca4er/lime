select *
from public."S_CampaignsCalls"
limit 10
/
with c as 
(
    select *, row_number() over (partition by "State" order by "StartTime" desc) as rn
    from public."S_CampaignsCalls"
    where "StartTime" >= '20190101'
)

select *
from c
left join public."Results" r on r."IDSeance" = c."IDSeance"
where rn <= 2
/
with r as 
(
    select *, row_number() over (partition by "Result", "Route" order by "StartTime" desc) as rn
    from public."Results"
    where "StartTime" >= '20190101'
)

select *
from r
where rn = 1
order by "Route", "Result"
/
select
    "TimeStart"
    , "TimeFinish"
    , "DurationFull" * 24 * 3600 as DurationFullSec-- Продол;ительность общая в секундах
    , "DurationTalk" * 24 * 3600 as DurationTalkSec
    , ' '
    , *
from public."S_Seances"
where "ID" = 5049737077
/

select "IDSeance"
from public."Results"
where "StartTime" >= '20190201'
group by "IDSeance"
having count(*) > 1
limit 10
/

select *
from public."Results"
where "IDSeance" = 5049823768
/
select *
from public."S_CampaignsCalls"
where "IDSeance" = 5049823768
/
select *
from public."S_Seances"
where "ID" = 5049823768
/
drop table if exists c_all
;

create temporary table c_all as
select
    c."ID" as ConnectionId
    , c."IDSeance"
    , c."TimeStart" as ConnectionTimeStart
    , c."DurationFull" * 24 * 3600 as DurationFullSec
    , c."DurationTalk" * 24 * 3600 as DurationTalkSec
    , r."ID" as ResultId
    , '' as del1
    , r."Result"
    , r."IDClient"
    , r."IDCredit"
    , '' as del2
    , cc."ID" as CampaignCallId
    , cc."StartTime" as CampaignsCallsTimeStart
    , cc."IDClient" as CampaignsCallClientId
    , cc."IDContragent"
    , s."AIDUser" as InfinityCollectorId
    , s."B1Number" as ClientPhone
    , s."SeanceType"
    , s."SeanceResult"
    , '' as del3
    , cc."State"
from public."S_Connections" c
inner join public."S_Seances" s on s."ID" = c."IDSeance"
left join public."Results" r on r."IDSeance" = c."IDSeance"
left join public."S_CampaignsCalls" cc on cc."IDSeance" = c."IDSeance"
where c."TimeStart" >= '20190220'
    and c."TimeStart" < '20190221' 
    and c."AWavFile" is not null
    and c."BWavFile" is not null
/
with CampaignCalls as 
(
    select
        c."ID" as ConnectionId
        , c."DurationFull" * 24 * 3600 as DurationFullSec
        , c."DurationTalk" * 24 * 3600 as DurationTalkSec
        , r."Result"
        , r."IDClient"
        , r."IDCredit"
        , cc."ID" as CampaignCallId
        , s."AIDUser" as InfinityCollectorId    -- ID коллектора, который возвонил вне кампании
        , s."B1Number" as ClientPhone
        , s."SeanceType"
        , cc."State" as CampaingCallState
    from public."S_Connections" c
    inner join public."S_Seances" s on s."ID" = c."IDSeance"
    left join public."Results" r on r."IDSeance" = c."IDSeance"
    left join public."S_CampaignsCalls" cc on cc."IDSeance" = c."IDSeance"
    where c."TimeStart" >= '20190220'
        and c."TimeStart" < '20190221' 
        and c."AWavFile" is not null
        and c."BWavFile" is not null
)

,calls as 
(
    select
        c.ConnectionId
        , c."campaigncallid"
        , c."IDClient"
        , c."clientphone"
        , ca."Extension" as InternalNumber
        , ca."AbonentName"
        , ca."CallResult"
        , c.CampaingCallState
        , ca."TimeStart"
        , c."durationfullsec"
        , c."durationtalksec"
    from CampaignCalls c
    left join public."S_CallsAndConnections" cac on c.ConnectionId = cac."IDConnection"
    left join public."S_Calls" ca on ca."ID" = cac."IDCall"
    where "campaigncallid" is not null  -- Звонки в рамках кампаний
        and "SeanceType" = 2            -- Исходящие звонки
)

select * 
from calls 
/*
    Звонок в рамках кампании состоит из двух частей:
    1. дозвон до клиента (InternalNumber начинается с 'z')
    2. перевод звонка на коллектора ожидающего клиента
    Перевод на коллектора может не состояться (клиент положил трубку и прочее)
*/
where InternalNumber not like 'z%'  
    or not exists 
    (
        select 1 from calls c2
        where c.campaigncallid = c2.campaigncallid
            and c2.InternalNumber not like 'z%'
    )
    
/

-- DB security
select
    uu."ID"
    , uu."Login"
    , uc."Contact"
from public."U_Contacts" uc
inner join public."U_Users" uu on uu."ID" = uc."IDAbonent"