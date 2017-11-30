CREATE FUNCTION [dbo].[tf_getScheduleJson](@cred int)
returns nvarchar(max)
as 

begin
return 
(
    select
        "Date"
        ,cast(Amount as numeric(18, 4)) as Amount
        ,cast("Percent" as numeric(18, 4)) as "Percent" 
        ,cast(Residue as numeric(18, 4)) as Residue
        ,cast(Total as numeric(18, 4)) Total
    from [dbo].[tf_getschedule](@cred)
    for json auto
) 
end

GO
