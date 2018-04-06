 drop table if exists dbo.tb253
 ;
 
 select
    dense_rank() over (order by clientid) as rank
    ,count(*) over (partition by clientid) as cnt
    ,*
into dbo.tb253
from doc.ClientDocumentMetadata
where ClientId in
    (
        select 
            ClientId
        from [Doc].[ClientDocumentMetadata]
        where DocumentType = 105
        group by ClientId, ContractNumber, DocumentType
        having count(*) > 1
    )
    and DocumentType = 105
;
/
with a as 
(
    select 
        count(*) over (partition by rank) as newCnt
        , * 
    from dbo.tb253 t
    where t.CreatedOn <= dateadd(d, -4, getdate()) 
        and not exists 
                (
                    select 1 from prd.ShortTermProlongation l
                    inner join prd.Product p on p.id = l.ProductId
                    where l.IsActive = 1
                        and l.StartedOn >= t.CreatedOn
                        and p.ContractNumber = t.ContractNumber
                )
)

select *
from a
where newCnt = cnt