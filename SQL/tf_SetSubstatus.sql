create   function client.tf_SetSubstatus(@ClientId int, @SubStatus int, @StartedOn datetime)
RETURNS @T table (ClientId int, UserStatusHistoryId int)
AS 
begin
    declare @Status int
    ;
    select @Status = @SubStatus / 100
    from client.EnumClientSubstatus ecs
    where ecs.Id = @SubStatus
           and exists 
                   (
                       select 1 from client.Client c
                       where c.Id = @ClientId
                   )
    ;
    
    exec client.sp_SetSubstatus @ClientId, @SubStatus, @Status, @StartedOn
    ;
    
    insert into @T
    select ClientId, id
    from client.UserStatusHistory ush
    where ClientId = @ClientId
        and @Status is not null
        and ush.IsLatest = 1
    ;
    
    return
end
GO

