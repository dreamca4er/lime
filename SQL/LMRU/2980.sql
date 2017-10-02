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
        ,case 
            when collector != 'everest'
            then 'transfer1'
            else 'transfer2'
        end as tableName
        ,case 
            when collector = 'prima'
            then N'ÂÛÏÈÑÊÀ ÈÇ ĞÅÅÑÒĞÀ ÄÎÃÎÂÎĞÎÂ ÎÒ #dt Ê ÀÃÅÍÒÑÊÎÌÓ ÄÎÃÎÂÎĞÓ ¹070416 îò 07.04.2016'
            when collector = 'everest'
            then N'ÂÛÏÈÑÊÀ ÈÇ ĞÅÅÑÒĞÀ ÄÎÃÎÂÎĞÎÂ ÎÒ #dt Ê ÀÃÅÍÒÑÊÎÌÓ ÄÎÃÎÂÎĞÓ ¹ 004 îò 03 îêòÿáğÿ 2016 ã.'
            when collector = 'creditExpress'
            then N'ÂÛÏÈÑÊÀ ÈÇ ĞÅÅÑÒĞÀ ÄÎÃÎÂÎĞÎÂ ÎÒ #dt Ê ÀÃÅÍÒÑÊÎÌÓ ÄÎÃÎÂÎĞÓ ¹1 îò 23.03.2017'
            when collector = 'bars'
                and transferDateTo <= '20161231'
            then N'ÂÛÏÈÑÊÀ ÈÇ ĞÅÅÑÒĞÀ ÄÎÃÎÂÎĞÎÂ ÎÒ #dt Ê ÀÃÅÍÒÑÊÎÌÓ ÄÎÃÎÂÎĞÓ ¹ÀÑÄ-001 îò 28.11.2014'
            when collector = 'bars'
                and transferDateFrom > '20161231'
            then N'ÂÛÏÈÑÊÀ ÈÇ ĞÅÅÑÒĞÀ ÄÎÃÎÂÎĞÎÂ ÎÒ #dt Ê ÀÃÅÍÒÑÊÎÌÓ ÄÎÃÎÂÎĞÓ ¹004 îò 28.11.2014'
        end as tableHeader
        ,case 
            when collector != 'bars'
                and transferDateTo <= '20170112'
            then 'mfo'
            when collector != 'bars'
                and transferDateFrom > '20170112'
            then 'mfk'
            when collector = 'bars'
                and transferDateTo <= '20170112'
            then 'mfo_bars_asd'
            when collector = 'bars'
                and transferDateFrom > '20170112'
            then 'mfk_bars_ooo'
        end as stamp
    from dates

    union

    select
        userid
        ,'return'
        ,returnDateFrom
        ,returnDateTo
        ,collector
        ,case 
            when collector != 'bars'
            then 'return1'
            else 'return2'
        end as tableName
        ,case 
            when collector = 'prima'
            then N'ÂÛÏÈÑÊÀ ÈÇ ĞÅÅÑÒĞÀ ÂÎÇÂĞÀÒÀ ÄÎÃÎÂÎĞÎÂ ÎÒ #dt Ê ÀÃÅÍÒÑÊÎÌÓ ÄÎÃÎÂÎĞÓ ¹070416 îò 07.04.2016'
            when collector = 'everest'
            then N'ÂÛÏÈÑÊÀ ÈÇ ĞÅÅÑÒĞÀ ÂÎÇÂĞÀÒÀ ÄÎÃÎÂÎĞÎÂ ÎÒ #dt Ê ÀÃÅÍÒÑÊÎÌÓ ÄÎÃÎÂÎĞÓ ¹ 004 îò 03 îêòÿáğÿ 2016 ã.'
            when collector = 'creditExpress'
            then N'ÂÛÏÈÑÊÀ ÈÇ ĞÅÅÑÒĞÀ ÂÎÇÂĞÀÒÀ ÄÎÃÎÂÎĞÎÂ ÎÒ #dt Ê ÀÃÅÍÒÑÊÎÌÓ ÄÎÃÎÂÎĞÓ ¹1 îò 23.03.2017'
            when collector = 'bars'
                and returnDateTo <= '20161231'
            then N'ÂÛÏÈÑÊÀ ÈÇ ĞÅÅÑÒĞÀ ÂÎÇÂĞÀÒÀ ÄÎÃÎÂÎĞÎÂ ÎÒ #dt Ê ÀÃÅÍÒÑÊÎÌÓ ÄÎÃÎÂÎĞÓ ¹ÀÑÄ-001 îò 28.11.2014'
            when collector = 'bars'
                and returnDateFrom > '20161231'
            then N'ÂÛÏÈÑÊÀ ÈÇ ĞÅÅÑÒĞÀ ÂÎÇÂĞÀÒÀ ÄÎÃÎÂÎĞÎÂ ÎÒ #dt Ê ÀÃÅÍÒÑÊÎÌÓ ÄÎÃÎÂÎĞÓ ¹ 004 ÎÒ 31.05.2017'
        end as tableHeader
        ,case 
            when collector != 'bars'
                and returnDateTo <= '20170112'
            then 'mfo'
            when collector != 'bars'
                and returnDateFrom > '20170112'
            then 'mfk'
            when collector = 'bars'
                and returnDateTo <= '20170112'
            then 'mfo_bars_asd'
            when collector = 'bars'
                and returnDateFrom > '20170112'
            then 'mfk_bars_ooo'
        end as stamp
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
    --where creditid = @InputCredit --200239
)

,fin as 
(
select
    ca.userid
    ,ca.creditid
    ,collector
    ,format(ca.collectorAssignStart, 'dd.MM.yyyy') as actionDate
    ,format(ca.overduestart, 'dd.MM.yyyy') as overduestart
    ,tableName
    ,replace(tableHeader, '#dt', format(ca.collectorAssignStart, 'dd.MM.yyyy')) as tableHeader
    ,stamp
    ,ca.collectorAssignStart as actionDateForOrder
from ca
inner join dateslist dl on (ca.collectorAssignStart >= dl.dateFrom or dl.dateFrom is null)
    and (ca.collectorAssignStart <= dl.dateTo or dl.dateTo is null)
    and dl.dir = 'transfer'
    and dl.collectorid = ca.collectorid

union

select
    ca.userid
    ,ca.creditid
    ,collector
    ,format(ca.collectorAssignEnd, 'dd.MM.yyyy')
    ,format(ca.overduestart, 'dd.MM.yyyy')
    ,tableName
    ,replace(tableHeader, '#dt', format(ca.collectorAssignEnd, 'dd.MM.yyyy')) as tableHeader
    ,stamp
    ,ca.collectorAssignEnd
from ca
inner join dateslist dl on (ca.collectorAssignEnd >= dl.dateFrom or dl.dateFrom is null)
    and (ca.collectorAssignEnd <= dl.dateTo or dl.dateTo is null)
    and dl.dir = 'return'
    and dl.collectorid = ca.collectorid
)
