drop table if exists [dbo].[TariffUpdateList]
;

create table [dbo].[TariffUpdateList]  ( 
	[clientid]      	int not null primary key,
	[fio]           	nvarchar(100) not null,
	[Email]         	nvarchar(50) not null,
	[PhoneNumber]   	nvarchar(11) null,
	[DateRegistered]	date not null,
	[Passport]      	nvarchar(10) null,
	[substatusName] 	nvarchar(50) null,
	[STTariffName]  	nvarchar(20) null,
	[STTariffId]    	int null,
	[STStatus]          nvarchar(20),
	[LTTariffName]  	int null,
	[LTTariffId]    	nvarchar(20) null,
	[LTStatus]          nvarchar(20)
	)
GO

insert [dbo].[TariffUpdateList]
select
    c.clientid
    ,cast(c.fio as nvarchar(100)) as fio
    ,cast(c.Email as nvarchar(50)) as Email
    ,cast(c.PhoneNumber as nvarchar(11)) as PhoneNumber
    ,cast(c.DateRegistered as date) as DateRegistered
    ,cast(c.Passport as nvarchar(10)) as Passport
    ,cast(c.substatusName as nvarchar(50)) as substatusName
    ,cast(ustt.TariffName as nvarchar(20)) as STTariffName
    ,ustt.TariffId as STTariffId
    ,case 
        when ustt.IsLatest = 1 then N'Текущий' 
        when ustt.IsLatest = 0 then N'Истекший' 
    end as STStatus
    ,cast(ultt.TariffName as nvarchar(20)) as LTTariffId
    ,ultt.TariffId as LTTariffName
    ,case 
        when ultt.IsLatest = 1 then N'Текущий' 
        when ultt.IsLatest = 0 then N'Истекший' 
    end as LTStatus
from client.vw_client c
outer apply
(
    select top 1
        ustt.TariffId
        ,ustt.TariffName
        ,ustt.IsLatest
    from client.vw_TariffHistory ustt
    where ustt.ClientId = c.clientid
        and ustt.ProductType = 1
    order by ustt.CreatedOn desc
) ustt
outer apply
(
    select top 1 
        ultt.TariffId
        ,ultt.TariffName
        ,ultt.IsLatest
    from client.vw_TariffHistory ultt
    where ultt.ClientId = c.clientid
        and ultt.ProductType = 2
    order by ultt.CreatedOn desc 
) ultt
where c.IsFrauder = 0
    and c.Status = 2
    and c.IsDead = 0
    and c.IsCourtOrdered = 0
    and c.BankruptType = 0
    and
    (
        exists
            (
                select 1 from prd.vw_product p
                where c.clientid = p.ClientId
                    and p.Status = 5
                    and datediff(d, p.DatePaid, getdate()) > 15
            )
        
        or
        
        not exists
            (
                select 1 from prd.product p
                where c.clientid = p.ClientId
            )
        
    )
    and not exists 
        (
            select 1 from prd.vw_product p
            where p.ClientId = c.clientid
                and p.Status not in (1, 5)
        )
;

delete tu
from dbo.TariffUpdateKonga tu
where exists 
    (
        select  1 from prd.vw_product p
        inner join client.vw_client c on c.clientid = p.ClientId
        where c.Passport = tu.Passport
            and p.status in (3, 4, 7)
    )
    or exists 
    (
        select 1 from client.vw_client c
        where c.Passport = tu.Passport
            and 
                (
                c.IsFrauder = 1
                or c.IsDead = 1
                or c.IsCourtOrdered = 1
                )
    )
;

update tu
set
    tu.ClientStatus = cast(replace(replace(us.ClientStatus, '{"ClientStatus":', ''), '}', '') as nvarchar(50))
    ,tu.CreditStatus = cast(replace(replace(c.CreditStatus, '{"CreditStatus":', ''), '}', '') as nvarchar(50))
from dbo.TariffUpdateKonga tu
outer apply
(
    select c.substatusName as ClientStatus
    from client.vw_Client c
    where c.Passport = tu.Passport
    for json auto, without_array_wrapper
) us(ClientStatus)
outer apply
(
    select 
        p.StatusName as CreditStatus
    from prd.vw_product p
    inner join client.vw_Client c on c.clientid = p.ClientId
    where not exists
        (
            select 1 from prd.vw_Product p2
            where p2.ClientId = p.ClientId
                and p2.Status != 1
                and p2.productid > p.productid
        )
        and c.Passport = tu.Passport
    for json auto, without_array_wrapper
) c(CreditStatus)
;

select *
from dbo.CustomList

insert dbo.CustomListUsers
(
    ClientId, CustomlistID
)
select
    tu.ClientId
    ,1068
from dbo.TariffUpdateList tu
inner join "KONGA-DB".Limezaim_Website.dbo.TariffUpdateLime kl on kl.ClientId = tu.ClientId
inner join "MANGO-DB".Limezaim_Website.dbo.TariffUpdateLime ml on ml.ClientId = tu.ClientId
/
drop table if exists dbo.TariffUpdateListFinal
;

CREATE TABLE [dbo].[TariffUpdateListFinal]  ( 
	[clientid]         	int NOT NULL,
	[fio]              	nvarchar(100) NOT NULL,
	[Email]            	nvarchar(50) NOT NULL,
	[PhoneNumber]      	nvarchar(11) NULL,
	[DateRegistered]   	date NOT NULL,
	[Passport]         	nvarchar(10) NULL,
	[substatusName]    	nvarchar(50) NULL,
	[STTariffName]     	nvarchar(20) NULL,
	[STTariffId]       	int NULL,
	[STStatus]         	nvarchar(20) NULL,
	[LTTariffName]     	nvarchar(20) NULL,
	[LTTariffId]       	int NULL,
	[LTStatus]         	nvarchar(20) NULL,
	[LimeCreditStatus] 	nvarchar(50) NULL,
	[KongaClientStatus]	nvarchar(50) NULL,
	[KongaCreditStatus]	nvarchar(50) NULL,
	[MangoClientStatus]	nvarchar(50) NULL,
	[MangoCreditStatus]	nvarchar(50) NULL,
	[score]            	numeric(17,6) NULL,
	[STNew]            	int NULL,
	[LTNew]            	int NULL,
	[STNewName]        	nvarchar(80) NULL,
	[LTNewName]        	nvarchar(80) NULL 
	)
GO

with t as 
(
    select *
    from 
    (
        values
        (1, 0.49, 2, null, 0.55, null)
        ,(2, 0.49, 3, null, 0.55, null)
        ,(3, 0.49, 4, null, 0.55, null)
        ,(4, 0.49, 5, null, 0.55, null)
        ,(5, 0.49, 6, null, 0.55, null)
        ,(6, 0.49, 7, null, 0.55, 5)
        ,(7, 0.49, 9, null, 0.55, 6)
        ,(8, 0.49, 9, null, 0.55, 7)
        ,(9, 0.49, 10, null, 0.55, 7)
        ,(10, 0.49, 11, null, 0.55, 8)
        ,(11, 0.49, 12, null, 0.55, 8)
        ,(12, 0.49, null, null, 0.55, 8)
    ) t(STOld, STScore, STNew, LTOld, LTScore, LTNew)
)

,score as 
(
    select *
    from #Score
)

,pre as 
(
    select
        tu.*
        ,p.ProductStatus as LimeCreditStatus
        ,kl.ClientStatus as KongaClientStatus
        ,kl.CreditStatus as KongaCreditStatus
        ,ml.ClientStatus as MangoClientStatus
        ,ml.CreditStatus as MangoCreditStatus
        ,s.score
        ,case 
            when s.score >= t.STScore
                and stt.id > tu.STTariffId
            then t.STNew 
        end as STNew
        ,case 
            when s.score >= t.LTScore 
                and ltt.id > tu.LTTariffId
            then t.LTNew 
        end as LTNew
        ,stt.Name as STNewName
        ,ltt.Name as LTNewName
    from dbo.TariffUpdateList tu
    inner join "KONGA-DB".Limezaim_Website.dbo.TariffUpdateLime kl on kl.ClientId = tu.ClientId
    inner join "MANGO-DB".Limezaim_Website.dbo.TariffUpdateLime ml on ml.ClientId = tu.ClientId
    inner join bi.vw_GoodClientsForTariffUpdate gc on gc.ClientId = tu.ClientId
    inner join score s on s.ClientId = tu.ClientId
    left join t on (t.STOld = tu.STTariffId or t.STOld is null)
        and (t.LTOld = tu.LTTariffId or t.LTOld is null)
    left join prd.ShortTermTariff stt on stt.id = t.STNew
    left join prd.LongTermTariff ltt on ltt.id = t.LTNew
    outer apply
    (
        select top 1
            p.StatusName as ProductStatus
        from prd.vw_product p
        where p.ClientId = tu.ClientId
            and p.status != 1
        order by p.ProductId desc
    ) p 
)

insert dbo.TariffUpdateListFinal 
select *
from pre
where STNew is not null or LTNew is not null

select *
from  dbo.TariffUpdateScore
/
select * -- update t set t.Islatest = 0
from client.UserShortTermTariff t
inner join dbo.TariffUpdateListFinal lf on t.ClientId = lf.clientid
    and lf.STNew is not null
    and lf.STTariffId = t.TariffId
where t.IsLatest = 1
;

select * -- update t set t.Islatest = 0
from client.UserLongTermTariff t
inner join dbo.TariffUpdateListFinal lf on t.ClientId = lf.clientid
    and lf.LTNew is not null
    and lf.LTTariffId = t.TariffId
where t.IsLatest = 1
;

-- insert dbo.TariffUpdateListFinal(ClientId, TariffId, CreatedOn, CreatedBy, IsLatest)
select
    lf.clientid as ClientId
    ,lf.STNew as TariffId
    ,getdate() as CreatedOn
    ,cast(0x0 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
from dbo.TariffUpdateListFinal lf
where lf.STNew is not null
;

-- insert dbo.TariffUpdateListFinal(ClientId, TariffId, CreatedOn, CreatedBy, IsLatest)
select
    lf.clientid as ClientId
    ,lf.LTNew as TariffId
    ,getdate() as CreatedOn
    ,cast(0x0 as uniqueidentifier) as CreatedBy
    ,1 as IsLatest
from dbo.TariffUpdateListFinal lf
where lf.LTNew is not null