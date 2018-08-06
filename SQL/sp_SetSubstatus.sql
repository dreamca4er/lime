create   procedure client.sp_SetSubstatus(@ClientId int, @SubStatus int, @Status int, @StartedOn datetime)

as 
begin
    update c set status = @Status, substatus = @SubStatus
    from client.Client c
    where c.id = @ClientId
    ;
    
    update ush set islatest = 0
    from [Client].[UserStatusHistory] ush
    where ush.clientid = @ClientId
    ;
    
    insert into [Client].[UserStatusHistory]
    (
        clientid, status, substatus, islatest, createdon, createdby
    )
    select 
        @ClientId
        ,@Status
        ,@SubStatus
        ,1
        ,@StartedOn
        ,cast(0x77 as uniqueidentifier)
    ;

end
GO

