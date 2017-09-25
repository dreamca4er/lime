with users as 
(
    select userid
    from syn_CmsUsers

    union

    select distinct dch.CollectorId
    from dbo.DebtorCollectorHistory dch
)

,dates  as
(
    select
        userid
        ,null as transferDateFrom
        ,'20170112' as transferDateTo
        ,null as returnDateFrom
        ,'20170112' as returnDateTo
        ,case 
            when u.userid = 1174
            then 'prima'
            when u.userid = 1157
            then 'everest'
            when u.userid = 1218
            then 'creditExpress'
        end as collector
    from users u
    where userid in (1174, 1157, 1218)

    union

    select
        userid
        ,'20170113' as transferDateFrom
        ,null as transferDateTo
        ,'20170113' as returnDateFrom
        ,null as returnDateTo
        ,case 
            when u.userid = 1174
            then 'prima'
            when u.userid = 1157
            then 'everest'
            when u.userid = 1218
            then 'creditExpress'
        end as collector
    from users u
    where userid in (1174, 1157, 1218)

    union

    select
        userid
        ,null as transferDateFrom
        ,'20160828' as transferDateTo
        ,null as returnDateFrom
        ,'20161231' as returnDateTo
        ,'bars' as collector
    from users
    where userid not in
      (0, 1000, 1173, 1184, 1375, 1165, 1229, 
        1282, 1351, 1162, 1158, 1166, 1049, 1168, 
        1038, 1237, 1198, 1174, 1157, 1218)

    union

    select
        userid
        ,'20160828' as transferDateFrom
        ,'20161231' as transferDateTo
        ,null as returnDateFrom
        ,'20161231' as returnDateTo
        ,'bars' as collector
    from users
    where userid not in
      (0, 1000, 1173, 1184, 1375, 1165, 1229, 
        1282, 1351, 1162, 1158, 1166, 1049, 1168, 
        1038, 1237, 1198, 1174, 1157, 1218)

    union

    select
        userid
        ,'20170531' as transferDateFrom
        ,'20170820' as transferDateTo
        ,'20170531' as returnDateFrom
        ,'20170820' as returnDateTo
        ,'bars' as collector
    from users
    where userid not in
      (0, 1000, 1173, 1184, 1375, 1165, 1229, 
        1282, 1351, 1162, 1158, 1166, 1049, 1168, 
        1038, 1237, 1198, 1174, 1157, 1218)
)

,dateslist as 
(
    select
        userid as collectorid
        ,'transfer' as dir
        ,transferDateFrom as dateFrom
        ,transferDateTo as dateTo
        ,collector
    from dates

    union

    select
        userid
        ,'return'
        ,returnDateFrom
        ,returnDateTo
        ,collector
    from dates
)

,ca as 
(
    select
        c.userid
        ,ca.creditid
        ,ca.collectorid
        ,overdueStart
        ,ca.collectorAssignStart
        ,ca.collectorAssignEnd
    from tf_getCollectorAssigns('19000101', getdate(), 0) ca
    inner join dbo.Credits c on c.id = ca.creditid
    where creditid = 44247
)

select
    ca.userid
    ,ca.creditid
    ,ca.collectorAssignStart as actionDate
    ,ca.overduestart
    ,concat(dl.dir, dl.collector, isnull('from' + dl.dateFrom, ''), isnull('to' + dl.dateTo, '')) as format    
from ca
inner join dateslist dl on (ca.collectorAssignStart >= dl.dateFrom or dl.dateFrom is null)
    and (ca.collectorAssignStart <= dl.dateTo or dl.dateTo is null)
    and dl.dir = 'transfer'
    and dl.collectorid = ca.collectorid

union

select
    ca.userid
    ,ca.creditid
    ,ca.collectorAssignEnd
    ,ca.overduestart
    ,concat(dl.dir, dl.collector, isnull('from' + dl.dateFrom, ''), isnull('to' + dl.dateTo, '')) as format
from ca
inner join dateslist dl on (ca.collectorAssignEnd >= dl.dateFrom or dl.dateFrom is null)
    and (ca.collectorAssignEnd <= dl.dateTo or dl.dateTo is null)
    and dl.dir = 'return'
    and dl.collectorid = ca.collectorid