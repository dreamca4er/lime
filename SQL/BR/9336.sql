/*
create table bi.PassportDoubleMainClient 
(
    PassportNumber nvarchar(10) not null unique
    , ClientId int  not null unique
    , timestamp timestamp
)

alter table bi.PassportDoubleMainClient add primary key (PassportNumber, ClientId)
*/

drop table if exists #priority
;

select
    subs.id as SubstatusId
    , v.*
into #priority
from 
(
    values
    (N'Активен. есть кредит', 1)
    , (N'Активен. есть тариф, нет кредитов', 2)
    , (N'Активен. Нужен тариф (повторый)', 3)
    , (N'Активен. нужен тариф', 4)
    , (N'Заблокирован. Ручная блокировка', 5)
    , (N'Заблокирован. Базовая блокировка КР', 6)
    , (N'Заблокирован. Скорринг-блокировка', 7)
    , (N'Заблокирован. BlackList', 8)
    , (N'Регистрация. 3-й шаг', 9)
    , (N'Регистрация. Профиль', 10)
) v(SubstatusName, Priority)
inner join client.EnumClientSubstatus subs on subs.Description = v.SubstatusName
;

drop table if exists #Passports
;

select
    i.Number
    , i.ClientId
    , p.Priority
    , c.SubStatus
    , uc.userId as StsUserId
into #Passports
from client."Identity" i
inner join client.Client c on c.id = i.ClientId
left join #priority p on p.SubstatusId = c.Substatus
left join sts.UserClaims uc on uc.ClaimValue = i.ClientId
    and uc.ClaimType = 'user_client_id'
where exists
    (
        select 1 from client."Identity" i2
        inner join client.Client c2 on c2.id = i2.ClientId
            and c2.Status < 4
        where i2.Number = i.Number
            and i2.ClientId != i.ClientId
    )
    and c.Status < 4
;

create index IX_Passports_Number on #Passports(Number)
;

/********************** Паспорта без кредитов или с единственным клиентом с кредитами **********************/
/*************************** Легко определить основной ЛК **********************/
drop table if exists #ToDelete
;

with p as 
(
    select 
        pa.Number
         , max(pr.ClientId) as ClientId
    from #Passports pa
    left join prd.vw_AllProducts pr on pr.ClientId = pa.ClientId
    group by pa.Number
    having count(distinct pr.ClientId) <= 1
)

,r as 
(
    select
        pass.*
        , pd.ClientId as MainClient
        , p.ClientId as SingleClientWithCredits
        , dense_rank() over (partition by pass.Number 
                                order by p.ClientId desc
                                        , pd.ClientId desc
                                        , pass.Priority
                                        , max(cal.OperationDate) desc
                                        , pass.ClientId desc) as ClientRank
    from #Passports pass
    left join p on p.number = pass.number
        and p.ClientId = pass.ClientId
    left join client.ClientActionLog cal on cal.ClientId = pass.ClientID
        and cal.OperationType = 1
    left join bi.PassportDoubleMainClient pd on pd.PassportNumber = pass.number
        and pd.ClientId = pass.ClientId
    where exists
        (
            select 1 from #Passports pa
            left join prd.vw_AllProducts pr on pr.ClientId = pa.ClientId
            where pa.Number = pass.Number
            group by pa.Number
            having count(distinct pr.ClientId) <= 1
        )
    group by 
        pass.Number
        , pass.ClientId
        , pass.Substatus
        , pass.Priority
        , pass.StsUserId
        , pd.Clientid
        , p.ClientId
)

select *, dense_rank() over (order by Number) % 5 as Pack
into #ToDelete
from r
where ClientRank != 1
;

create index IX_ToDelete_Pack_ClientId on #ToDelete(Pack, ClientId)
;

exec bi.sp_DeletePassportDouble
;
GO
/********************** Паспорта с кредитами у нескольких клиентов **********************/
/*************************** Сложнее определить основной ЛК **********************/
drop table if exists #ToDelete
;

drop table if exists #cl
;

with p as 
(
    select 
        pa.Number
        , pa.ClientId
        , max(case when p.Status != 1 then isnull(p.CreatedOn, pr.StartedOn) end) as LastProductStart
        , count(pr.ProductId) as AllProductsCount
        , count(p.ProductId) as NewProductsCount
        , count(case when p.Status not in (1, 5, 6) then 1 end) as ActiveProductCount
    from #Passports pa
    left join prd.vw_AllProducts pr on pr.ClientId = pa.ClientId
    left join prd.vw_product p on p.Productid = pr.Productid
    group by pa.Number, pa.ClientId
)

select
    pass.*
    , pd.ClientId as MainClient
    , p.LastProductStart
    , p.AllProductsCount
    , p.NewProductsCount
    , p.ActiveProductCount
    , dense_rank() over (partition by pass.Number 
                            order by pd.ClientId desc
                                    , p.ActiveProductCount desc
                                    , p.LastProductStart desc
                                    , p.AllProductsCount desc
                                    , pass.Priority
                                    , pass.ClientId desc) as ClientRank
into #cl
from #Passports pass
left join p on p.number = pass.number
    and p.ClientId = pass.ClientId
left join bi.PassportDoubleMainClient pd on pd.PassportNumber = pass.number
    and pd.ClientId = pass.ClientId
where exists
    (
        select 1 from #Passports pa
        left join prd.vw_AllProducts pr on pr.ClientId = pa.ClientId
        where pa.Number = pass.Number
        group by pa.Number
        having count(distinct pr.ClientId) > 1
    )
;

delete d
from bi.PassportDoubleMainClient d
left join client."Identity" i on i.Number = d.PassportNumber
    and i.ClientId = d.ClientId
where i.id is null
;

insert bi.PassportDoubleMainClient
(
    PassportNumber,ClientId
)
select
    number
    , ClientId
from #cl cl
where ClientRank = 1
    and not exists
    (
        select 1 from bi.PassportDoubleMainClient pd
        where pd.PassportNumber = cl.number
    )
;

select *, dense_rank() over (order by Number) % 5 as Pack
into #ToDelete
from #cl
where ClientRank != 1
    and ActiveProductCount = 0
;

exec bi.sp_DeletePassportDouble
;
