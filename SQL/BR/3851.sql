select id
into #c
from client.Client
where id in
(
449590
,2004255
,2004165 
,2004151 
,2004106 
,2004069
,2003972 
,1999618
,2003905
,2003777
,2003760
,2003734
,2003711 
,2003701 
,2003641 
,2003618
,2003461
,2003432
,2003402 
,2003398
,2003347
,2003197
,2003114
,2003108
,1999638
,2003043
,1999657
,2003019
,2003007 
,2002933
,1999690
,2002911
,2002879 
,2002878
,1999703
,1999727
,2000078
,2000061 
,2000012
,1999938
,1999885
,1999865 
,1999845 
,2018623
,2018597
,2018585
,2018573 
,2018528
,2018508 
,2017886
,2017872
,2018291
,2018284 
,2018264
,2018240
,2018121
,2018090
,2017946 
,2017869 
,2017823
,2016549
,2017660
,2007299
,2017621
,2017585
,2017492
,2017427 
,2017408
,2017299 
,2017290 
,2017274 
,2017258
,2017232
,2017187
,2017180 
,2017104
,2017091
,2017090
,2017068
,2017064
,2017030
,2016972
,2016970
,2016957 
,2016926 
,2016715
,2088788
,2088783
,2088510
,2088017
,2088199
,2088122
,2088095
,2087863
,2088032
,2087695
,2087684
,2087517
,2087372
,2087343
,2087286
,2087141
,2087062
,2086952
,2086862
,2086731
,2086723
,2056373
,2086514
,2086428
,2088705
,2088624
,2088555
,2088344
,2088118
,2088117
,2087785
,2088040
,2087639
,2087397
,2087264
,2087151
,2086898
,2086626
,2086534
,2126722
,2126627
,2126590
,2126564
,2126560
,2125823
,2126488
,2126194
,2126165
,2126163
,2126044
,2125991
,2125699
,2125697
,2125395
,2125670
,2125657
,2125613
,2125389
,2125287
,2125222
,2124898
,2125176
,2125163
,2125159
,2125048
,2125020
,2125000
,2124990
,2124881
,2124792
,2124767
,2124758
,2124689
,2124569
,2124617
,2124603
,2126119
,2126355
,2125831
,2125587
,2125311
,2124748
,2125139
,2125107
,2124679
,2124503
,2124446
,2124397
,2124360
,2157249
,2157247
,2157206
,2157139
,2157115
,2157070
,2157069
,2157047
,2157009
,2156985
,2156970
,2156966
,2156880
,2156638
,2156745
,2156592
,2156568
,2156547
,2156441
,2156424
,2156423
,2156396
,2156302
,2156290
,2156316
,2156259
,2156257
,2156118
,2156056
,2156051
,2156017
,2155979
,2155878
,2155863
,2155847
,2155820
,2155771
,2155664
,2157162
,2157054
,2156918
,2156874
,2156536
,2156490
,2156360
,2156330
,2156287
,2156168
,2156152
,2155831
,2155799
,2155737
,2155643
,2105305
,2105332
,2105334
,2105052
,2104820
,2104753
,2104665
,2104438
,2104353
,2104330
,2104303
,2104287
,2103980
,2103770
,2103506
,2103502
,2103453
,2103446
,2103385
,2103221
,2103167
,2103139
,2103054
,2103011
,2102899
,2102839
,2102672
,2102667
,2102600
,2102268
,2104973
,2104924
,2104570
,2104375
,2103602
,2103525
,2103458
,2103329
,2102709
,2102686
,2139617
,2139614
,2139613
,2139596
,2139564
,2139440
,2139414
,2139403
,2139364
,2139288
,2139277
,2139275
,2139274
,2139196
,2139099
,2138985
,2138951
,2138897
,2138895
,2138693
,2138691
,2138644
,2138628
,2138565
,2138522
,2138515
,2138488
,2138480
,2138402
,2138349
,2138338
,2138305
,2138279
,2138236
,2138208
,2138207
,2138170
,2138029
,2137888
,2138259
,2138226
,2138224
,2138181
,2138071
,2138068
,2138044
,2137970
,2137857
,1987441
,1987445
,1987449
,1987456
,1987212
,1987332
,1986108
,1987396
,1987412
,1987072
,1987065
,1987011
,1986968
,1986955
,1986946
,1986795
,1986736
,1986795
,1986789
,1986509
,1986506
,1986492
,1986420
,1986346
,1986126
,1986073
,1986009
,1985982
,1985912
,1985905 
,1985832
,1985717 
,1985712
,1985690
,1985667
,1985648
,1985589
,1985556 
,1985492
,1985450
,1985438
,1982601
,1982622
,1982609
,1982170
,1982165
,1981832
,1982091
,1981989 
,1981852
,2000302
,2000640
,2000592
,2000586
,2000582
,2000564
,2000538
,2000534
,2000371
)
/
select
    c.id as ClientId
    ,crr.Score
    ,p.Productid
    ,p.CreatedOn
    ,p.StartedOn
    ,p.DatePaid
    ,p.ContractNumber
    ,p.StatusName
    ,p.PaymentWayName
    ,p.Amount
    ,isnull(replace(replace(replace(cdm.DocumentTypes, '"dt":"', ''), '"}', ''), '{', ''), N'Нет') as DocumentTypes
    ,TotalAmount
    ,TotalPercent
    ,OtherPaid
    ,(p.Amount - isnull(Paid.PaidM1, 0)) * 100.0 / p.Amount as NPLM1
    ,(p.Amount - isnull(Paid.PaidM2, 0)) * 100.0 / p.Amount as NPLM2
    ,(p.Amount - isnull(Paid.PaidM3, 0)) * 100.0 / p.Amount as NPLM3
from #c c
left join prd.vw_product p on p.ClientId = c.id
outer apply
(
    select distinct
        ecdt.Description as dt
    from doc.ClientDocumentMetadata cdm
    inner join doc.EnumClientDocumentType ecdt on ecdt.id = cdm.DocumentType
    where cdm.ClientId = c.id
    for json auto, without_array_wrapper
) cdm (DocumentTypes)
outer apply
(
    select
        sum(case when cast(cb.DateOperation as date) <= eomonth(format(dateadd(d, p2.Period, p2.StartedOn), 'yyyyMM01'), 1) then cb.TotalAmount end) as PaidM1
        ,sum(case when cast(cb.DateOperation as date) <= eomonth(format(dateadd(d, p2.Period, p2.StartedOn), 'yyyyMM01'), 2) then cb.TotalAmount end) as PaidM2
        ,sum(case when cast(cb.DateOperation as date) <= eomonth(format(dateadd(d, p2.Period, p2.StartedOn), 'yyyyMM01'), 3) then cb.TotalAmount end) as PaidM3
        ,sum(cb.TotalAmount) as TotalAmount
        ,sum(cb.TotalPercent) as TotalPercent
        ,sum(cb.TotalDebt - cb.TotalAmount - cb.TotalPercent) as OtherPaid
    from bi.CreditBalance cb
    inner join prd.vw_Product p2 on p2.ProductId = cb.ProductId
    where cb.ProductId = p.Productid
        and cb.InfoType = 'payment'
) Paid
outer apply
(
    select top 1 crr.Score
    from cr.CreditRobotResult crr
    where crr.ClientId = c.id
        and crr.CreatedOn < p.CreatedOn
) crr
/
select
    c.SNILS
    ,c.id as ClientId
    ,c.DateRegistered
    ,p.*
    ,crr.Score
from client.Client c
outer apply
(
    select top 1
        p.Productid
        ,p.StartedOn
        ,p.CreatedOn
        ,p.Amount
        ,p.StatusName
        ,p.DatePaid
        ,p.PaymentWayName
        ,paid.*
    from prd.vw_product p
    outer apply
    (
        select 
            sum(cb.TotalAmount) as TotalAmount 
            ,sum(cb.TotalPercent) as TotalPercent
            ,sum(cb.TotalDebt - cb.TotalAmount - cb.TotalPercent) as OtherPaid 
        from bi.CreditBalance cb
        where cb.ProductId = p.ProductId
            and cb.InfoType = 'payment'
    ) as paid
    where p.ClientId = c.id
        and p.Status >= 2
    order by p.StartedOn desc
) p
outer apply
(
    select top 1 crr.Score
    from cr.CreditRobotResult crr
    where crr.ClientId = c.id
        and crr.CreatedOn < p.CreatedOn
    order by crr.CreatedOn desc
) crr
where c.SNILS in 
    (
        select SNILS
        from client.Client
        where SNILS != '00000000000'
        group by SNILS
        having count(*) > 1
    )
order by c.SNILS