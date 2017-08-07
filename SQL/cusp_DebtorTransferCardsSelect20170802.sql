
CREATE PROCEDURE [dbo].[cusp_DebtorTransferCardsSelect]
	@PageNum int,
	@PageSize int,
	@SortBy nvarchar(150) = N'',
	@SortDirection bit,
	@ExternalCollectorGroupName nvarchar(100) = null,
	@ClientIds nvarchar(max) = null,
	@DelayDaysFrom int = null,
	@DelayDaysTo int = null,
	@InternalCollectorId int = null,
	@ExternalCollectorId int = null,
	@DateTransferFrom datetime = null,
	@DateTransferTo datetime = null,
	@DateRecallFrom datetime = null,
	@DateRecallTo datetime = null,
	@TransferType int = null,
	@isFraud bit = null,
	@RowCount int output
as
begin
	declare @now datetime = getdate(),
		@today date = getdate(),
		@creditStatusDelay int = 3,
		@debtorStatusFullyPaid int = 3
	declare @ExternalCollectorGroupId int =	isnull(
		(select [Id] from [AclRoles] where [Name] = @ExternalCollectorGroupName), 0)
    
	--Извлечем Id клиентов из строки
	declare @xml xml
	declare @clientIdList table
	(
		[ClientId] int not null
	)
	set @xml = cast(('<X>' + replace(@ClientIds, ',', '</X><X>') + '</X>') as xml)
	insert into @clientIdList
		select C.value('.', 'int') from @xml.nodes('X') as X(C)
	declare @results table
	(
		[Id] int identity not null,
		[DebtorId] int not null,
		[UserId] int not null,
		[AgreementNum] nvarchar(50) not null,
		[ClientFio] nvarchar(152) not null,
		[CreditStatus] int not null,
		[ExternalCollectorName] nvarchar(506) null,
		[CourtName] nvarchar(200) null,
		[CessionName] nvarchar(200) null,
		[DebtorTransferType] int null,
		[TransferDate] datetime null,
		[RecallDate] datetime null,
		[DelayDays] int not null
	)
	declare @sortedResults table
	(
		[Id] int not null,
		[DebtorId] int not null,
		[UserId] int not null,
		[AgreementNum] nvarchar(50) not null,
		[ClientFio] nvarchar(152) not null,
		[CreditStatus] int not null,
		[ExternalCollectorName] nvarchar(506) null,
		[CourtName] nvarchar(200) null,
		[CessionName] nvarchar(200) null,
		[DebtorTransferType] int null,
		[TransferDate] datetime null,
		[RecallDate] datetime null,
		[DelayDays] int not null,
		rownum int 
	)
	--Клиенты, переданные по цессии
	insert into @results
		(
			[DebtorId],
			[UserId],
			[AgreementNum],
			[ClientFio],
			[CreditStatus],
			[ExternalCollectorName],
			[CourtName],
			[CessionName],
			[DebtorTransferType],
			[TransferDate],
			[RecallDate],
			[DelayDays]
		)
		select 
			d.[Id]
			,u.Id
			,c.[DogovorNumber]
			,u.Lastname + ' ' + u.Firstname + coalesce(' ' + u.Fathername, '')
			,ch.[Status]
			,null
			,null
			,ce.[Name]
			,3
			,ctce.[TransferDate]
			,case
				when ugl.[AclRoleId] is null then null
				else dh.[DateCreated]
			 end
			,case
				when c.[Status] = @creditStatusDelay then datediff(day, cast(ch.[DateStarted] as date), @today)
				else 0
			 end
		from DebtorTransferCession ctce with (nolock)
		left join Debtors d with (nolock) on d.[Id] = ctce.[DebtorId]
		left join DebtorCollectorHistory dh with (nolock) on dh.[DebtorId] = d.[Id]
		left join [CmsContent_LimeZaim].[dbo].[Users] au with (nolock) on au.[UserId] = dh.[CollectorId]
		left join [AclAdminRoles] ugl with (nolock) on ugl.[AdminId] = dh.[CollectorId] and ugl.[AclRoleId] = @ExternalCollectorGroupId
		left join [dbo].[Credits] c with (nolock) on c.[Id] = d.[CreditId]
		left join [dbo].[FrontendUsers] u with (nolock) on u.Id = c.[UserId]
		left join [dbo].[CreditStatusHistory] ch with (nolock) on ch.CreditId = c.Id and ch.[DateStarted] =
			(
				select max([DateStarted])
				from [dbo].[CreditStatusHistory] with (nolock)
				where [CreditId] = c.[Id]
			)
		left join Cessions ce with (nolock) on ce.[Id] = ctce.[CessionId]
		left join UserCards uc with (nolock) on uc.UserId = u.Id 
		where d.[Status] <> @debtorStatusFullyPaid and dh.[IsLatest] = 1 and cast(ctce.[TransferDate] as date) >= cast(dh.DateCreated as date)
			and (@ClientIds is null or @ClientIds = N'' or c.[UserId] in (select [ClientId] from @clientIdList))
			and (@DelayDaysFrom is null or ch.[Status] = @creditStatusDelay and datediff(day, cast(ch.[DateStarted] as date), @today) >= @DelayDaysFrom)
			and (@DelayDaysTo is null or ch.[Status] = @creditStatusDelay and datediff(day, cast(ch.[DateStarted] as date), @today) <= @DelayDaysTo)
			and (@InternalCollectorId is null or @InternalCollectorId = 0 or dh.[CollectorId] = @InternalCollectorId)
			and (@ExternalCollectorId is null or @ExternalCollectorId = 0)
			and (@DateTransferFrom is null or cast(ctce.[TransferDate] as date) >= @DateTransferFrom)
			and (@DateTransferTo is null or cast(ctce.[TransferDate] as date) <= @DateTransferTo)
			and (@DateRecallFrom is null or dh.[DateCreated] >= @DateRecallFrom)
			and (@DateRecallTo is null or dh.[DateCreated] <= @DateRecallTo)
			and (@TransferType is null or @TransferType = 3)
			and (@IsFraud is null or (@IsFraud = 0 and (uc.IsFraud is null or uc.IsFraud = 0)) or (uc.IsFraud = 1 and @IsFraud = 1))
	
	--Клиенты, переданные внешним коллекторам (аутсорсинг)
	insert into @results
		(
			[DebtorId],
			[UserId],
			[AgreementNum],
			[ClientFio],
			[CreditStatus],
			[ExternalCollectorName],
			[CourtName],
			[CessionName],
			[DebtorTransferType],
			[TransferDate],
			[RecallDate],
			[DelayDays]
		)
		select 
			d.[Id]
			,u.Id
			,c.[DogovorNumber]
			,u.Lastname + ' ' + u.Firstname + coalesce(' ' + u.Fathername, '')
			,ch.[Status]
			,case
				when ugl.[AclRoleId] is null then null
				else au.[UserName]
			 end
			,null
			,null
			,case
				when ugl.[AclRoleId] is null then null
				else 1
			 end
			,case
				when ugl.[AclRoleId] is null then null
				else dh.[DateCreated]
			 end
			,case
				when uglPrev.[AclRoleId] is null then null
				else dhPrev.[DateCreated]
			 end
			,case
				when c.[Status] = @creditStatusDelay then datediff(day, cast(ch.[DateStarted] as date), @today)
				else 0
			 end
		from Debtors d with (nolock)
		left join DebtorCollectorHistory dh with (nolock) on dh.[DebtorId] = d.[Id]
		left join [dbo].[Credits] c with (nolock) on c.[Id] = d.[CreditId]
		left join [dbo].[FrontendUsers] u with (nolock) on u.Id = c.[UserId]
		left join [dbo].[CreditStatusHistory] ch with (nolock) on ch.CreditId = c.Id and ch.[id] =
			(
				select max([id])
				from [dbo].[CreditStatusHistory] with (nolock)
				where [CreditId] = c.[Id]
			)
		left join [CmsContent_LimeZaim].[dbo].[Users] au with (nolock) on au.[UserId] = dh.[CollectorId]
		left join [AclAdminRoles] ugl with (nolock)
			on ugl.[AdminId] = dh.[CollectorId]
		left join DebtorCollectorHistory dhPrev with (nolock)
			on dhPrev.[Id] = (select max(Id) from [DebtorCollectorHistory] where [DebtorId] = dh.[DebtorId] and [Id] < dh.[Id])
		left join [AclAdminRoles] uglPrev with (nolock)
			on uglPrev.[AdminId] = dhPrev.[CollectorId] and uglPrev.[AclRoleId] = @ExternalCollectorGroupId
			
		left join UserCards uc with (nolock) on uc.UserId = u.Id 
		where d.[Status] <> @debtorStatusFullyPaid and dh.[IsLatest] = 1 and ugl.[AclRoleId] = @ExternalCollectorGroupId
			and (@ClientIds is null or @ClientIds = N'' or c.[UserId] in (select [ClientId] from @clientIdList))
			and (d.[Id] not in (select [DebtorId] from @results))
			and (@DelayDaysFrom is null or ch.[Status] = @creditStatusDelay and datediff(day, cast(ch.[DateStarted] as date), @today) >= @DelayDaysFrom)
			and (@DelayDaysTo is null or ch.[Status] = @creditStatusDelay and datediff(day, cast(ch.[DateStarted] as date), @today) <= @DelayDaysTo)
			and (@InternalCollectorId is null or @InternalCollectorId = 0 or dh.[CollectorId] = @InternalCollectorId)
			and (@ExternalCollectorId is null or @ExternalCollectorId = 0 or dh.[CollectorId] = @ExternalCollectorId)
			and (@DateTransferFrom is null or ugl.[AclRoleId] is not null and cast(dh.[DateCreated] as date) >= @DateTransferFrom)
			and (@DateTransferTo is null or ugl.[AclRoleId] is not null and cast(dh.[DateCreated] as date) <= @DateTransferTo)
			and (@DateRecallFrom is null or ugl.[AclRoleId] is not null and cast(dhPrev.[DateCreated] as date) >= @DateRecallFrom)
			and (@DateRecallTo is null or ugl.[AclRoleId] is not null and cast(dhPrev.[DateCreated] as date) <= @DateRecallTo)
			and (@IsFraud is null or (@IsFraud = 0 and (uc.IsFraud is null or uc.IsFraud = 0)) or (uc.IsFraud = 1 and @IsFraud = 1))
			and (@TransferType is null or @TransferType = 1 and ugl.[AclRoleId] is not null)
	
	--Сортировка записей
	if ((@SortBy = '' or @SortBy is null) or @SortBy = N'AgreementNum' and @SortDirection = 1)
	begin
		insert into @sortedResults
			select *,
			row_number() over (order by AgreementNum desc, TransferDate desc) rownum	
			from @results
	end
	else if (@SortBy = N'AgreementNum' and @SortDirection = 0)
	begin
		insert into @sortedResults
			select *,
			row_number() over (order by AgreementNum asc, TransferDate desc) rownum
			from @results
	end
	else if (@SortBy = N'UserId' and @SortDirection = 0)
	begin
		insert into @sortedResults
			select *,
			row_number() over (order by UserId asc, TransferDate desc) rownum
			from @results
	end
	else if (@SortBy = N'UserId' and @SortDirection = 1)
	begin
		insert into @sortedResults
			select *,
			row_number() over (order by UserId desc, TransferDate desc) rownum
			from @results
	end
	else if (@SortBy = N'ClientFio' and @SortDirection = 0)
	begin
		insert into @sortedResults
			select *,
			row_number() over (order by ClientFio asc, TransferDate desc) rownum	
			from @results
	end
	else if (@SortBy = N'ClientFio' and @SortDirection = 1)
	begin
		insert into @sortedResults
			select *,
			row_number() over (order by ClientFio desc, TransferDate desc) rownum	
			from @results
	end
	else if (@SortBy = N'TransferredCreditStatus' and @SortDirection = 0)
	begin
		insert into @sortedResults
			select *,
			row_number() over (order by CreditStatus asc, AgreementNum desc, TransferDate desc) rownum	
			from @results
	end
	else if (@SortBy = N'TransferredCreditStatus' and @SortDirection = 1)
	begin
		insert into @sortedResults
			select *,
			row_number() over (order by CreditStatus desc, AgreementNum desc, TransferDate desc) rownum	
			from @results
	end
	else if (@SortBy = N'ExternalCollectorName' and @SortDirection = 0)
	begin
		insert into @sortedResults
			select *,
			row_number() over (order by ExternalCollectorName asc, AgreementNum desc, TransferDate desc) rownum	
			from @results
	end
	else if (@SortBy = N'ExternalCollectorName' and @SortDirection = 1)
	begin
		insert into @sortedResults
			select *,
			row_number() over (order by ExternalCollectorName desc, AgreementNum desc, TransferDate desc) rownum	
			from @results
	end
	else if (@SortBy = N'TransferType' and @SortDirection = 0)
	begin
		insert into @sortedResults
			select *,
			row_number() over (order by DebtorTransferType asc, AgreementNum desc, TransferDate desc) rownum
			from @results
	end
	else if (@SortBy = N'TransferType' and @SortDirection = 1)
	begin
		insert into @sortedResults
			select *,
			row_number() over (order by DebtorTransferType desc, AgreementNum desc, TransferDate desc) rownum	
			from @results
	end
	else if (@SortBy = N'TransferDate' and @SortDirection = 0)
	begin
		insert into @sortedResults
			select *,
			row_number() over (order by TransferDate asc) rownum	
			from @results
	end
	else if (@SortBy = N'TransferDate' and @SortDirection = 1)
	begin
		insert into @sortedResults
			select *,
			row_number() over (order by TransferDate desc) rownum	
			from @results
	end
	else if (@SortBy = N'RecallDate' and @SortDirection = 0)
	begin
		insert into @sortedResults
			select *,
			row_number() over (order by RecallDate asc) rownum	
			from @results
	end
	else if (@SortBy = N'RecallDate' and @SortDirection = 1)
	begin
		insert into @sortedResults
			select *,
			row_number() over (order by RecallDate desc) rownum	
			from @results
	end
	else if (@SortBy = N'DelayDays' and @SortDirection = 0)
	begin
		insert into @sortedResults
			select *,
			row_number() over (order by DelayDays asc, AgreementNum desc, TransferDate desc) rownum	
			from @results
	end
	else if (@SortBy = N'DelayDays' and @SortDirection = 1)
	begin
		insert into @sortedResults
			select *,
			row_number() over (order by DelayDays desc, AgreementNum desc, TransferDate desc) rownum	
			from @results
	end
	delete from @results
	
	--Выборка для постраничной навигации
	select @RowCount = count(Id) from @sortedResults
	if (@RowCount < @PageSize)
	begin
		set @PageSize = @RowCount
	end
	select [Id],
		[DebtorId],
		[UserId],
		[AgreementNum],
		[ClientFio],
		[CreditStatus],
		[ExternalCollectorName],
		[CourtName],
		[CessionName],
		[DebtorTransferType],
		[TransferDate],
		[RecallDate],
		[DelayDays]
	from @sortedResults as seq 
	where seq.rownum between @PageSize * (@PageNum - 1) + 1 and @PageSize * @PageNum
	order BY [seq].[rownum]
end

GO
