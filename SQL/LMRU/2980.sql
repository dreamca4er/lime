select
    userid
    ,null as dateFrom
    ,cast('20160828' as date) as dateTo
    ,case 
        when userid = 1174 then 'Everest'
        when userid = 1157 then 'Prima'
        when userid = 1218 then 'CreditExpress'
        else 'Bars'
    end as collectorType
from syn_CmsUsers
where userid not in
    ( 1173, 1184, 1375, 1165, 1229, 1282, 1351, 1162, 1158, 1166, 1049, 1168, 1038, 1237, 1198)

union

select
    userid
    ,cast('20160829' as date) as dateFrom
    ,cast('20161231' as date) as dateTo
    ,case 
        when userid = 1174 then 'Everest'
        when userid = 1157 then 'Prima'
        when userid = 1218 then 'CreditExpress'
        else 'Bars'
    end as collectorType
from syn_CmsUsers
where userid not in
    ( 1173, 1184, 1375, 1165, 1229, 1282, 1351, 1162, 1158, 1166, 1049, 1168, 1038, 1237, 1198)

union

select
    userid
    ,cast('20170101' as date) as dateFrom
    ,cast('20170530' as date) as dateTo
    ,case 
        when userid = 1174 then 'Everest'
        when userid = 1157 then 'Prima'
        when userid = 1218 then 'CreditExpress'
    end as collectorType
from syn_CmsUsers
where userid in (1174, 1157, 1218)

union

select
    userid
    ,cast('20170531' as date) as dateFrom
    ,cast('20170820' as date) as dateTo
    ,case 
        when userid = 1174 then 'Everest'
        when userid = 1157 then 'Prima'
        when userid = 1218 then 'CreditExpress'
        else 'Bars'
    end as collectorType
from syn_CmsUsers
where userid not in
    ( 1173, 1184, 1375, 1165, 1229, 1282, 1351, 1162, 1158, 1166, 1049, 1168, 1038, 1237, 1198)

union

select
    userid
    ,cast('20170821' as date) as dateFrom
    ,null as dateTo
    ,case 
        when userid = 1174 then 'Everest'
        when userid = 1157 then 'Prima'
        when userid = 1218 then 'CreditExpress'
    end as collectorType
from syn_CmsUsers
where userid in (1174, 1157, 1218)