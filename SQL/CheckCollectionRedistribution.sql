declare
    @dateFrom datetime2 = '20180625'
;

declare
    @dateFromChar nvarchar(20) = format(@dateFrom, 'yyyyMMdd')
;

execute (
N'
select 
    CreatedOn
    ,Message
from store.log
where cast(CreatedOn as date) = ''' + @dateFromChar + '''
    and CreatedOn >= ''' + @dateFromChar + ' 03:00''
    and CreatedOn < ''' + @dateFromChar + ' 07:00''
    and ServiceUuid = ''col''
    and message like N''%распр%''
    order by CreatedOn 
    '
    )
    