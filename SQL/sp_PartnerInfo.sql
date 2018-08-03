
ALTER PROCEDURE [Mkt].[sp_PartnerInfo](@dateFrom date, @dateTo date, @partnerList nvarchar(100) = null) 
as 
begin
drop table if exists #WebmasterList
;
/*
declare 
    @dateFrom date = '20180601'
    ,@dateTo date = '20180613'
    ,@Confirmed bit = 1
;
*/

select
    d.dt1 as dt
    ,w.*
into #WebmasterList
from 
(
    select
        ts.id
        ,ts.Name as PartnerName
        ,json_value(Parameters, '$.webmaster_id') as WebmasterId
    from mkt.TrafficSource ts
    inner join Mkt.TrafficSourceTransitionLog tl on tl.TrafficSourceId = ts.id
    inner join mkt.leads l on l.Id = ts.Id
    where ts.id in (select value from openjson('[' + @partnerList +']'))
        or @partnerList is null
    union
    
    select 
        h.LeadId
        ,h.PartnerName
        ,WebmasterId
    from mkt.vw_PostbackHistory h
    where LeadId in (select value from openjson('[' + @partnerList +']'))
        or @partnerList is null
) w
cross join bi.tf_gendate(@dateFrom, @dateTo) d
;

select 
    ts.Id
    ,cast(tl.CreatedOn as date) as dt
    ,ts.name
    ,json_value(tl.Parameters, '$.webmaster_id') as WebmasterId
    ,count(tl.id) as TransitionCount
into #t
from Mkt.TrafficSourceTransitionLog tl
inner join mkt.TrafficSource ts on ts.Id = tl.TrafficSourceId
    and cast(tl.CreatedOn as date) between @dateFrom and @dateTo
inner join mkt.Leads l on l.id = ts.id
where l.id in (select value from openjson('[' + @partnerList +']'))
    or @partnerList is null
group by ts.Id, ts.name, json_value(tl.Parameters, '$.webmaster_id'), cast(tl.CreatedOn as date)

select 
    h.PartnerId
    ,h.WebmasterId
    ,cast(h.PostbackDate as date) as dt
    ,count(case when h.ConversionType = 2 then 1 end) as CorrectPostBackCreditCount
    ,sum(case when h.ConversionType = 2 then p.Amount end) as CorrectPostBackCreditSum
    ,count(case when h.ConversionType = 1 then 1 end) as CorrectPostBackRegCount
into #c
from mkt.vw_PostbackHistory h
left join prd.Product p on  p.id = h.EntityId
--    left join client.vw_client cl on cl.clientid = p.clientId
where cast(h.PostbackDate as date) between @dateFrom and @dateTo
    and h.IsError = 0
    and (h.PartnerId in (select value from openjson('[' + @partnerList +']'))
        or @partnerList is null)
group by h.PartnerId, h.PartnerName, h.WebmasterId, cast(h.PostbackDate as date)


select
    w.Id
    ,w.dt
    ,w.WebmasterId
    ,w.PartnerName
    ,isnull(t.TransitionCount, 0) as TransitionCount
    ,isnull(c.CorrectPostBackCreditCount, 0) as CorrectPostBackCreditCount
    ,isnull(c.CorrectPostBackCreditSum, 0) as CorrectPostBackCreditSum
    ,isnull(c.CorrectPostBackRegCount, 0) as CorrectPostBackRegCount
--    ,row_number() over (partition by w.PartnerName order by case when w.WebmasterId is null then 2 else 1 end, isnull(t.TransitionCount, 0) desc) as TransitionCountRank
--     ,row_number() over (partition by w.PartnerName order by case when w.WebmasterId is null then 2 else 1 end, isnull(c.CorrectPostBackCreditCount, 0) desc) as CorrectPostBackCreditCountRank
--     ,row_number() over (partition by w.PartnerName order by case when w.WebmasterId is null then 2 else 1 end, isnull(c.CorrectPostBackCreditSum, 0) desc) as CorrectPostBackCreditSumRank
--     ,row_number() over (partition by w.PartnerName order by case when w.WebmasterId is null then 2 else 1 end, isnull(c.CorrectPostBackRegCount, 0) desc) as CorrectPostBackRegCountRank
from #WebmasterList w
left join #t t on t.id = w.Id
    and (w.WebmasterId = t.WebmasterId or w.WebmasterId is null and t.WebmasterId is null)
    and w.dt = t.dt
left join #c c on c.PartnerId = w.id
    and (w.WebmasterId = c.WebmasterId or w.WebmasterId is null and c.WebmasterId is null)
    and w.dt = c.dt
;
end
GO
