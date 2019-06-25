declare
    @Date date = cast(getdate() as date)
;

select 
    b.*
    , r.Reason
from dbo.br9625 b
left join prd.vw_product p on p.Productid = b.Loan_originator_ID
outer apply
(
    select
        case
            when p.Status in (4, 5, 7)
            then N'Статус "Просрочен", "Продлен", "Погашен"'
            when datediff(d, Listed_on, @Date) > 60
            then N'Пройдет 60 дней с даты выкупа к ' + format(@date, 'dd.MM.yyyy')
            when dateadd(d, p.Period, p.StartedOn) < @Date
            then N'Дата закрытия по договору до ' + format(@date, 'dd.MM.yyyy')
            else N'Не нужно выкупать к ' + format(@date, 'dd.MM.yyyy')
        end as Reason
) r
where r.Reason = N'Не нужно выкупать к ' + format(@date, 'dd.MM.yyyy')



