CREATE TABLE [bi].[CustomList]  ( 
    [ID]                int IDENTITY(1000,1) NOT NULL,
    [Name]              nvarchar(50) NOT NULL,
    [Description]       nvarchar(512) NULL,
    [Type]              nvarchar(20) NULL,
    [ListDate]          date NOT NULL,
    [CustomFieldDesc]   nvarchar(1024) NULL,
    CONSTRAINT [CustomList_pk] PRIMARY KEY CLUSTERED([ID])
 ON [PRIMARY])
ON [PRIMARY]
    WITH (
        DATA_COMPRESSION = NONE
    )
GO


CREATE TABLE [bi].[CustomListUsers]  ( 
    [CustomlistID]  int NOT NULL,
    [ClientId]      int NOT NULL,
    [DateCreated]   datetime2(0) NULL,
    [CustomField1]  int NULL,
    [CustomField2]  int NULL,
    CONSTRAINT [PK_dbo_UserCustomList] PRIMARY KEY CLUSTERED([CustomlistID],[ClientId])
 ON [PRIMARY])
ON [PRIMARY]
    WITH (
        DATA_COMPRESSION = NONE
    )
GO
set identity_insert [bi].[CustomList] on
;

insert [bi].[CustomList]
(
    ID,Name,Description,Type,ListDate,CustomFieldDesc
)
select ID,Name,Description,Type,ListDate,CustomFieldDesc
from [dbo].[CustomList]
;

set identity_insert [bi].[CustomList] off
;

insert [bi].[CustomListUsers]
select *
from [dbo].[CustomListUsers]


create index IX_CustomlistID_bi_CustomListUsers on [bi].[CustomListUsers](CustomlistID)
create index IX_ClientId_bi_CustomListUsers on [bi].[CustomListUsers](ClientId)