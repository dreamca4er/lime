create or alter function bi.sf_GenProductUId(@guid uniqueidentifier)
returns nvarchar(40) as 
begin
    
    declare
        @cleanguid nvarchar(36) = replace(@guid, '-', '')
        , @retguid nvarchar(40)
    ;
    
    with a as 
    (
        select top 32
            g.guid
            , row_number() over (order by 1/0)  as Num
        from sys.objects 
        cross join (select @cleanguid as guid) g
    )
    
    select
        @retguid = concat(@guid, '-', right(convert(nvarchar(2), convert(binary(1), sum(c.GuidDigit * Ord) % 16), 2), 1))
    from a
    outer apply
    (
        select
            convert(int, convert(binary(1), '0x0' + substring(a.guid, a.Num, 1), 1)) as GuidDigit
            , (Num + 9) % 10 + 1 as Ord
        
    ) c
    ;
    
    return @retguid

end
GO


select count(*)--update top (10000) p set Uid = bi.sf_GenProductUId(newid())
from prd.Product p
where p.ProductType in (1, 2)
    and not exists
    (
        select 1 from prd.ShortTermStatusLog sl
        where sl.ProductId = p.id
            and sl.Status in (1, 5, 6)
            and sl.StartedOn < '20191028'
    )
    and not exists
    (
        select 1 from prd.LongTermStatusLog sl
        where sl.ProductId = p.id
            and sl.Status in (1, 5, 6)
            and sl.StartedOn < '20191028'
    )
    and Uid is null
GO