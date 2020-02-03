
/*
CREATE TABLE [Ecc].[EmailCommunication]  ( 
	[Id]                    	int IDENTITY(1,1) NOT NULL,
	[ProviderName]          	nvarchar(max) NULL,
	[EmailFrom]             	nvarchar(max) NULL,
	[EmailTo]               	nvarchar(max) NULL,
	[Subject]               	nvarchar(max) NULL,
	[Body]                  	nvarchar(max) NULL,
	[DeliveryState]         	int NOT NULL,
	[InteractionId]         	int NOT NULL,
	[ProviderRequestInfoId] 	int NOT NULL,
	[DeliveryStatusDetails] 	nvarchar(max) NULL,
	[ProviderMessageId]     	nvarchar(max) NULL,
	[Timestamp]             	timestamp NOT NULL,
	[CreatedOn]             	datetime2 NOT NULL,
	[ModifiedOn]            	datetime2 NULL,
	[ModifiedBy]            	uniqueidentifier NULL,
	[CreatedBy]             	uniqueidentifier NOT NULL,
	[StatusType]            	int NOT NULL DEFAULT ((0)),
	[InteractionModelJson]  	nvarchar(max) NULL,
	[TemplateOvveridingJson]	nvarchar(max) NULL,
	[SentOn]                	datetime NULL,
	CONSTRAINT [PK_Ecc.EmailCommunication] PRIMARY KEY CLUSTERED([Id])
 ON [PRIMARY])
ON [PRIMARY]
	TEXTIMAGE_ON [PRIMARY]
	WITH (
		DATA_COMPRESSION = NONE
	)
GO
ALTER TABLE [Ecc].[EmailCommunication]
	ADD CONSTRAINT [FK_Ecc.EmailCommunication_Ecc.ProviderRequestInfo_ProviderRequestInfoId]
	FOREIGN KEY([ProviderRequestInfoId])
	REFERENCES [Ecc].[ProviderRequestInfo]([Id])
	ON DELETE CASCADE 
	ON UPDATE NO ACTION 
GO
ALTER TABLE [Ecc].[EmailCommunication]
	ADD CONSTRAINT [FK_Ecc.EmailCommunication_Ecc.Interaction_InteractionId]
	FOREIGN KEY([InteractionId])
	REFERENCES [Ecc].[Interaction]([Id])
	ON DELETE CASCADE 
	ON UPDATE NO ACTION 
GO
CREATE NONCLUSTERED INDEX [IX_ProviderRequestInfoId]
	ON [Ecc].[EmailCommunication]([ProviderRequestInfoId])
	WITH (	
		DATA_COMPRESSION = NONE
	)
	ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_InteractionId]
	ON [Ecc].[EmailCommunication]([InteractionId])
	WITH (	
		DATA_COMPRESSION = NONE
	)
	ON [PRIMARY]
GO


CREATE TABLE [Ecc].[SmsCommunication]  ( 
	[Id]                    	int IDENTITY(1,1) NOT NULL,
	[Header]                	nvarchar(max) NOT NULL,
	[PhoneNumber]           	nvarchar(max) NULL,
	[Body]                  	nvarchar(max) NOT NULL,
	[CrossSystemId]         	uniqueidentifier NOT NULL,
	[SmsDeliveryStatus]     	int NOT NULL,
	[ErrorDescription]      	nvarchar(max) NULL,
	[InteractionId]         	int NOT NULL,
	[ProviderRequestInfoId] 	int NOT NULL,
	[DeliveryStatusDetails] 	nvarchar(max) NULL,
	[ProviderMessageId]     	nvarchar(max) NULL,
	[Timestamp]             	timestamp NOT NULL,
	[CreatedOn]             	datetime2 NOT NULL,
	[ModifiedOn]            	datetime2 NULL,
	[ModifiedBy]            	uniqueidentifier NULL,
	[CreatedBy]             	uniqueidentifier NOT NULL,
	[StatusType]            	int NOT NULL DEFAULT ((0)),
	[InteractionModelJson]  	nvarchar(max) NULL,
	[TemplateOvveridingJson]	nvarchar(max) NULL,
	[SentOn]                	datetime NULL,
	CONSTRAINT [PK_Ecc.SmsCommunication] PRIMARY KEY CLUSTERED([Id])
 ON [PRIMARY])
GO
ALTER TABLE [Ecc].[SmsCommunication]
	ADD CONSTRAINT [FK_Ecc.SmsCommunication_Ecc.ProviderRequestInfo_ProviderRequestInfoId]
	FOREIGN KEY([ProviderRequestInfoId])
	REFERENCES [Ecc].[ProviderRequestInfo]([Id])
	ON DELETE CASCADE 
	ON UPDATE NO ACTION 
GO
ALTER TABLE [Ecc].[SmsCommunication]
	ADD CONSTRAINT [FK_Ecc.SmsCommunication_Ecc.Interaction_InteractionId]
	FOREIGN KEY([InteractionId])
	REFERENCES [Ecc].[Interaction]([Id])
	ON DELETE CASCADE 
	ON UPDATE NO ACTION 
GO

CREATE TABLE [Ecc].[Interaction]  ( 
	[Id]                  	int IDENTITY(1,1) NOT NULL,
	[InteractionStatus]   	int NOT NULL,
	[Comment]             	nvarchar(max) NULL,
	[SucceededOn]         	datetime2 NULL,
	[IsAccountable]       	bit NOT NULL,
	[SentOn]              	datetime2 NULL,
	[SentByUserUid]       	nvarchar(max) NULL,
	[SentByUser]          	bit NOT NULL,
	[ClientId]            	int NOT NULL,
	[ProductId]           	int NULL,
	[Type]                	int NOT NULL,
	[TemplateUid]         	uniqueidentifier NOT NULL,
	[MaskItemsJson]       	nvarchar(max) NULL,
	[InteractionModelJson]	nvarchar(max) NULL,
	[Timestamp]           	timestamp NOT NULL,
	[CreatedOn]           	datetime2 NOT NULL,
	[ModifiedOn]          	datetime2 NULL,
	[ModifiedBy]          	uniqueidentifier NULL,
	[CreatedBy]           	uniqueidentifier NOT NULL,
	CONSTRAINT [PK_Ecc.Interaction] PRIMARY KEY CLUSTERED([Id])
 ON [PRIMARY])
ON [PRIMARY]
	TEXTIMAGE_ON [PRIMARY]
	WITH (
		DATA_COMPRESSION = NONE
	)
GO
CREATE TABLE [Ecc].[ProviderRequestInfo]  ( 
	[Id]                       	int IDENTITY(1,1) NOT NULL,
	[Request]                  	nvarchar(max) NOT NULL,
	[Response]                 	nvarchar(max) NULL,
	[IsSucceeded]              	bit NOT NULL,
	[ProviderStatus]           	nvarchar(max) NULL,
	[ProviderStatusDescription]	nvarchar(max) NULL,
	[ProviderTypeFullName]     	nvarchar(max) NULL,
	[ExceptionMessage]         	nvarchar(max) NULL,
	[OccuredOn]                	datetime NULL,
	[Timestamp]                	timestamp NOT NULL,
	[CreatedOn]                	datetime2 NOT NULL,
	[CreatedBy]                	uniqueidentifier NOT NULL,
	CONSTRAINT [PK_Ecc.ProviderRequestInfo] PRIMARY KEY CLUSTERED([Id])
 ON [PRIMARY])
ON [PRIMARY]
	TEXTIMAGE_ON [PRIMARY]
	WITH (
		DATA_COMPRESSION = NONE
	)
GO
*/