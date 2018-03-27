
CREATE PROCEDURE [dict].[spParsePhoneRegion]
as
begin 
	drop table if exists #ClearedRegion
	create table #ClearedRegion (Region nvarchar(200))

	insert #ClearedRegion
	select distinct reverse( substring(reverse(r.Region), 1, charindex('|',reverse(r.Region),  1)-1) ) + ' ' rst
	from [stg].[PhoneRegions] r
	where r.Region like '%|%'

	insert #ClearedRegion
	select distinct r.Region + ' '
	from [stg].[PhoneRegions] r
	where r.Region not like '%|%'
		and r.Region != ''
	except 
	select region
	from #ClearedRegion

	drop table if exists #MatchedRegion
	create table #MatchedRegion (
		AOGUID nvarchar(255)
		, RegionCode nvarchar(4)
		, FindPat nvarchar(200)
		, Region nvarchar(200) 
		)

	;with preReg as
	(
		select a.AOGUID
			, a.REGIONCODE
			, '%' + replace(
						replace(
							replace(
								replace(
									replace(a.FORMALNAME, ' ', '%')
										, '-', '%'
										), '/', '%'
									), N'автономный', ''
								), N'округ', ''
							) + N'[^А-я]%' patrn
			, case
				when a.REGIONCODE = '83' then N'%Ямало[^А-я]%'
				else ''
			 end as ExceptionPatrn
		from dict.addrobj a
		where a.ACTSTATUS = 1
			and a.AOLEVEL = 1
			and a.LIVESTATUS = 1
	)
	insert #MatchedRegion
	select r.AOGUID
		, r.REGIONCODE
		, r.patrn
		, cr.Region
	from preReg r
	inner join #ClearedRegion cr on cr.Region like r.patrn
		and cr.Region not like r.ExceptionPatrn
	order by 2

	delete from dbo.PhoneRegion;

		insert dbo.PhoneRegion (Code, numFrom, numTo, RegionCode, RegionAOGUID, IsMobile)
		select r.ABC_DEF
			, r.numFrom
			, r.numTo
			, m.RegionCode
			, m.AOGUID
			, case when r.ABC_DEF like '9%' then 1 else 0 end as IsMobile
		from [stg].[PhoneRegions] r
		inner join #MatchedRegion m on reverse( substring(reverse(r.Region), 1, charindex('|',reverse(r.Region),  1)-1) ) = m.Region
		where r.Region like '%|%'

		insert dbo.PhoneRegion (Code, numFrom, numTo, RegionCode, RegionAOGUID, IsMobile)
		select r.ABC_DEF
			, r.numFrom
			, r.numTo
			, m.RegionCode
			, m.AOGUID
			, case when r.ABC_DEF like '9%' then 1 else 0 end as IsMobile
		from [stg].[PhoneRegions] r
		inner join #MatchedRegion m on r.Region = m.Region
		where r.Region not like '%|%'
end

GO
