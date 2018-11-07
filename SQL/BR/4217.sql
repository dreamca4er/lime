create table bi.DDLChanges
(
    id           int identity(1,1),
    EventDate    datetime not null default current_timestamp,
    EventType    nvarchar(100),
    EventDDL     nvarchar(MAX),
    DatabaseName nvarchar(255),
    SchemaName   nvarchar(255),
    ObjectName   nvarchar(255),
    HostName     nvarchar(255),
    IPAddress    varchar(32),
    ProgramName  nvarchar(255),
    LoginName    nvarchar(255),
    ServerName   nvarchar(255)
)
;

insert bi.DDLChanges
(
    EventType
    ,ObjectType
    ,EventDDL
    ,DatabaseName
    ,SchemaName
    ,ObjectName
    ,ServerName
)
select
    N'Initial control'
    ,'SP'
    ,object_definition([object_id])
    ,db_name()
    ,object_schema_name([object_id])
    ,object_name([object_id])
    ,@@servername
from sys.procedures

union all

select
    N'Initial control'
    ,'VIEW'
    ,object_definition([object_id])
    ,db_name()
    ,object_schema_name([object_id])
    ,object_name([object_id])
    ,@@servername
from sys.views

union all

select
    N'Initial control'
    ,'FUNCTION'
    ,object_definition([object_id])
    ,db_name()
    ,object_schema_name([object_id])
    ,object_name([object_id])
    ,@@servername
from sys.objects
where type_desc like '%FUNCTION%'
;

CREATE OR ALTER TRIGGER CaptureDDLChanges
    ON DATABASE
    FOR 
        create_procedure, alter_procedure, drop_procedure
        ,create_function, alter_function, drop_function
        ,create_view, alter_view, drop_view
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EventData XML = EVENTDATA(), @ip VARCHAR(32);

    SELECT @ip = client_net_address
        FROM sys.dm_exec_connections
        WHERE session_id = @@SPID;

    INSERT bi.DDLChanges
    (
        EventType,
        EventDDL,
        SchemaName,
        ObjectName,
        DatabaseName,
        HostName,
        IPAddress,
        ProgramName,
        LoginName,
        ServerName
    )
    SELECT
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]',   'NVARCHAR(100)'), 
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'NVARCHAR(MAX)'),
        @EventData.value('(/EVENT_INSTANCE/SchemaName)[1]',  'NVARCHAR(255)'), 
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]',  'NVARCHAR(255)'),
        DB_NAME(), HOST_NAME(), @ip, PROGRAM_NAME(), SUSER_SNAME(), @@servername;
END
GO

