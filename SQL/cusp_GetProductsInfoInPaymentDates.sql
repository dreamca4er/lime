drop procedure if exists [dbo].[cusp_GetProductsInfoInPaymentDates]
GO

CREATE PROCEDURE [dbo].[cusp_GetProductsInfoInPaymentDates]
(
	@dates nvarchar(1000)
    ,@skip int = 0
    ,@take int = null
    ,@overdueOnly bit = null
    ,@productType int = null
)
AS
begin

declare
    @productCount int
;

select @productCount = (select count(*) from prd.Product)
;

select @dates = replace(replace(replace(@dates, '\', ''), '"[', '['), ']"', ']')
;

select @take = 
    case 
        when @take is not null
        then @take
        when @productCount = 0
        then 1 
        else @productCount
    end
;

with dates as 
(
    select convert (date, q.value, 102) dt
    from openjson (@dates) q
)


,pre as 
(
    select
        p.UserId
        ,stp.Product_Id
        ,p.ContractNumber
        ,1 as productType
    from prd.ShortTermProlongation stp
    inner join prd.Product p on p.Id = stp.Product_Id
    outer apply
    (
        select top 1 stsl.Status
        from prd.ShortTermStatusLog stsl
        where stsl.Product_Id = stp.Product_Id
        order by stsl.StartedOn desc
    ) sl
    where cast(dateadd(d, stp.Period, stp.StartedOn) as date) in (select dt from dates)
        and sl.Status = case
                            when @overdueOnly = 1
                            then 4
                            else sl.Status
                        end

    union

    select
        p.UserId
        ,p.id
        ,p.ContractNumber
        ,1 as productType
    from prd.Product p
    inner join prd.ShortTermCredit stc on stc.id = p.id
    inner join dates d on d.dt = cast(dateadd(d, stc.Period, p.StartedOn) as date) 
    outer apply
    (
        select top 1 stsl.Status
        from prd.ShortTermStatusLog stsl
        where stsl.Product_Id = stc.id
        order by stsl.StartedOn desc
    ) sl
    where not exists 
                    (
                        select 1 from prd.ShortTermProlongation stp
                        where stp.Product_Id = p.id
                            and d.dt between cast(stp.StartedOn as date) and cast(dateadd(d, stp.Period, stp.StartedOn) as date)
                    )
        and sl.Status = case
                            when @overdueOnly = 1
                            then 4
                            else sl.Status
                        end
    union

    select
        p.UserId
        ,lts.Product_Id
        ,p.ContractNumber
        ,2 as productType
    from dates d
    inner join prd.LongTermScheduleLog ltsl on ltsl.StartedOn <= d.dt
        and ltsl.StartedOn = (
                                select max(ltsl1.StartedOn)
                                from prd.LongTermScheduleLog ltsl1
                                where ltsl.Product_Id = ltsl1.Product_Id
                                    and ltsl1.StartedOn <= d.dt
                              )
    inner join prd.LongTermSchedule lts on lts.Id = ltsl.Schedule_Id
    inner join prd.Product p on p.Id = lts.Product_Id
    outer apply
    (
        select top 1 ltsl.Status
        from prd.LongTermStatusLog ltsl
        where ltsl.Product_Id = p.Id
        order by ltsl.StartedOn desc
    ) sl
    where exists
            (
                select 1 from OPENJSON(lts.ScheduleSnapshot)
                with (Date date)
                where Date = d.dt
            )
        and sl.Status = case
                            when @overdueOnly = 1
                            then 4
                            else sl.Status
                        end
)

select  *
from pre
where productType = case
                        when isnull(@productType, 0) != 0
                        then @productType
                        else productType
                    end 
order by Product_id offset @skip rows fetch next @take rows only;
;

end

GO

--exec [dbo].[cusp_GetProductsInfoInPaymentDates] '\"[20171218]\"', 0, 1000, 0, 1