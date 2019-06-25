select 
    b.*
    , case
        when p.Status in (4, 5, 7)
        then N'Статус "Просрочен", "Продлен", "Погашен"'
        when datediff(d, Listed_on, '20190610') > 60
        then N'Пройдет 60 дней с даты выкупа к 20190610'
        when dateadd(d, p.Period, p.StartedOn) < '20190610'
        then N'Дата закрытия по договору до 20190610'
        else N'Не нужно выкупать к 20190610'
    end as Reason
from dbo.br9483 b
left join prd.vw_product p on p.Productid = b.Loan_originator_ID
--where p.Status in (4, 7)
--    or datediff(d, Listed_on, '20190610') > 60
--    or dateadd(d, p.Period, p.StartedOn) < '20190610'
/

select *
from prd.vw_Insurance p
where productid in (1065754,1066020,1066026,1066040)

select *
from prd.vw_product
where ContractNumber in
 (
'7500080251'
,'7500079794'
,'7500080277'
,'7500080245'
 )




