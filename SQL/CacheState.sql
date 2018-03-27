 select * --delete
 from cache.State
 where id in
 (
    select a.Id
     from (
          select ClientId
          from [Doc].[ClientDocumentMetadata]
          where DocumentType=105
          group by ClientId, ContractNumber, DocumentType
          having count(*)>1
     ) t1
     cross apply(
        select s.Id 
        from [Sts].[UserClaims] c
        join [Cache].[State] s on s.[Key] = convert(nvarchar(50), UserId) + '_AG_False' 
            and s.ServiceUuid = 'Api-Client'
            and ClaimValue=t1.ClientId and ClaimType='user_client_id'
     ) a
 )
 
