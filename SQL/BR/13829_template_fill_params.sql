with vals as 
(
    select *
    from
    (
        values
        ('a', 'a_value1')
        , ('a', 'a_value2')
        , ('b', 'b_value')
        , ('c', 'c_value')
    ) vals(Parameter, Value)
)

,t as 
(
    select 1 as TemplateId, '{a} and {b} and {c}' as Template, '["a", "b", "c"]' as ParametersList
    union all
    select 2 as TemplateId, '{c} and {b}' as Template, '["c", "b"]' as ParametersList
)

,unnest as 
(
    select
        t.TemplateId
        , t.Template
        , j."key" as ParameterNum
        , j.value as ToReplace
        , v.Value as ReplaceWith
    from t
    outer apply openjson(t.ParametersList) j
    left join vals v on v.Parameter = j.value
)

, cte(Template, ParameterNum, TemplateId) as 
(
    select 
        replace(u.Template, '{' + u.ToReplace + '}', u.ReplaceWith) as Template
        , u.ParameterNum
        , u.TemplateId
    from unnest u
    where u.ParameterNum = 0
    
    union all
    
    select
        replace(cte.Template, '{' + u.ToReplace + '}', u.ReplaceWith) as Template
        , u.ParameterNum
        , cte.TemplateId
    from cte
    inner join unnest u on u.ParameterNum = cte.ParameterNum + 1
        and u.TemplateId = cte.TemplateId
)

select
    TemplateId
    , Template
from cte
where not exists
    (
        select 1 from cte cte2
        where cte2.TemplateId = cte.TemplateId
            and cte2.ParameterNum > cte.ParameterNum
    )