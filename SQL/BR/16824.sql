with a as 
(
    select *
    from
    (
        values
        ('2.1', 77.902, 103.869)
        , ('2.2.1', 95.778, 127.704)
        , ('2.2.2', 46.409, 61.879)
        , ('2.3.1.1', 350.349, 365.000)
        , ('2.3.1.2', 109.992, 146.656)
        , ('2.3.2.1', 297.510, 365.000)
        , ('2.3.2.2', 96.699, 128.932)
        , ('2.3.3.1', 267.643, 356.857)
        , ('2.3.3.2', 292.743, 365.000)
        , ('2.3.3.3', 64.983, 86.644)
        , ('2.3.4.1', 137.483, 183.311)
        , ('2.3.4.2', 151.075, 201.433)
        , ('2.3.4.3', 36.733, 48.977)
        , ('2.3.5.1', 54.027, 72.036)
        , ('2.3.5.2', 52.824, 70.432)
        , ('2.3.5.3', 49.875, 66.500)
        , ('2.3.5.4', 36.417, 48.556)
        , ('2.4.1.1', 32.688, 43.584)
        , ('2.4.1.2', 28.143, 37.524)
        , ('2.4.1.3', 25.819, 34.425)
        , ('2.4.2', 26.401, 35.201)
    ) v(id, f, t)
)

--insert mkt.CentralBankPskValue(    LoanTypeId,PskAverageValue,PskMaximumValue,DateFrom,DateTo)
select 
    lt.Id as LoanTypeId
    , a.f as PskAverageValue
    , a.t as PskMaximumValue
    , '20200101' as DateFrom
    , '20200331' as DateTo
--    , prev.*
from a
inner join mkt.CentralBankLoanType lt on lt.ItemNumber = a.Id
outer apply
(
    select top 1 b.PskMaximumValue,b.PskAverageValue
    from mkt.CentralBankPskValue b
    where b.LoanTypeId = lt.Id
    order by b.DateFrom desc
)prev