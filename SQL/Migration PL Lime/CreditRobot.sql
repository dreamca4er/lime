
select top 10 *
from CreditRobotRequests
where DateCreated >= '20190501'
    and userid = 155924

select top 10 *
from CreditRobotVerdictRequests
where DateCreated >= '20190501'
    and userid = 155924
    


select *
from CreditRobotReports
where DateCreated >= '20190501'
    and ApplicationId = '96d62432e3d9456792e3bd898b174b5f'


select *
from BikReports
where DateCreated >= '20190501'
    and userid = 156045

/
select
    left(XmlRequest, 1)
    , cast(DateCreated as date) as dt
    , count(*)
from CreditRobotRequests
where DateCreated >= '20180901'
    and DateCreated < '20181001'
    and ResultType in (1, 2, 3)
group by 
    left(XmlRequest, 1)
    , cast(DateCreated as date)
/

select
    req.id
    , req.UserId as ClientId
    , 3 as CreditOrderStatus -- Done
    , isnull(ver.Verdict, req.Verdict) as Result
    , req.IpAddress as StartOrderIpAddress
    , req.DateCreated as CreatedOn
    , cast(convert(binary(8), req.CreatedByUserId) as uniqueidentifier) as CreatedBy
    , req.ApplicationId
from dbo.CreditRobotRequests req
left join dbo.CreditRobotVerdictRequests ver on ver.ApplicationId = req.ApplicationId
    and ver.Success = 1
where req.DateCreated >= '20180901' -- Месяц начала работы нового КР
    and left(req.XmlRequest, 1) = '{'
    and req.Verdict <= 1    -- 1/0/-1
    and (req.Verdict != -1 or req.Verdict = -1 and ver.Verdict is not null) -- Обработанные ручные рассмотрения
    
/
select *
from CreditRobotReports
where DateCreated >= '20190501'
    and ApplicationId = '96d62432e3d9456792e3bd898b174b5f'