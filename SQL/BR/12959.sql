select
    count(case when crr.AnalysisResult in (4, 5, 7) then 1 end) as Blocked 
    , count(case when crr.AnalysisResult in (3, 9) then 1 end) as Manual
    , count(case when crr.AnalysisResult in (1, 2, 8) then 1 end) as Success
from cr.CreditRobotResult crr
left join cr.EnumAnalysisResult ar on ar.Id = crr.AnalysisResult
where crr.CreatedOn >= '20190406'
;

select
    count(*)
from client.UserShortTermTariff th
inner join sts.vw_admins a on a.Id = th.CreatedBy
    and a.Roles like '%verif%'
where th.CreatedOn >= '20190406'
;

select count(*)
from client.UserStatusHistory ush
inner join sts.vw_admins a on a.Id = ush.CreatedBy
    and a.Roles like '%verif%'
where ush.CreatedOn >= '20190406'
    and ush.Status = 3