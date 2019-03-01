select
    p.Productid
    , p.ClientId
    , p.PaymentWayName as "Канал"
    , case
        when p.Status = 5 then N'Погашен'
        when p.Status = 4 then N'Просрочен'
        else N'Активен'
    end as "Статус продукта"
    , p.StatusName
    , iif(c.IsFrauderChangedAt >= p.CreatedOn 
            and c.IsFrauderChangedAt < isnull(ap2.CreatedOn, getdate()), 1, null) 
            as "Получили маркировку мошенник в нужный период"
from prd.vw_AllProducts ap
inner join prd.vw_product p on p.Productid = ap.ProductId
left join client.Client c on c.id = ap.ClientId
    and c.IsFrauder = 1
outer apply
(
    select p2.CreatedOn
    from prd.vw_AllProducts ap2
    inner join prd.Product p2 on p2.id = ap2.ProductId
    where ap2.ClientId = ap.ClientId
        and ap2.ProductNum = 2
) ap2
where ap.StartedOn between '20181101' and '20190121'
    and ap.ProductNum = 1
/
select
    c.id as ProductId
    , c.UserId as ClientId
    , pw.Description as "Канал"
    , case
        when c.Status = 2 then N'Погашен'
        when c.Status = 3 then N'Просрочен'
        else N'Активен'
    end as "Статус продукта"
    , c.Status
    , iif(uc.IsFraudDateChanged >= c.DateCreated
            and uc.IsFraudDateChanged <= isnull(c2.DateCreated, getdate()), 1, null) 
            as "Получили маркировку мошенник в нужный период"
from dbo.Credits c
inner join dbo.EnumDescriptions pw on pw.Value = c.Way
    and pw.Name = 'MoneyWay'
left join dbo.UserCards uc on uc.UserId = c.UserId
    and uc.IsFraud = 1
outer apply
(
    select c2.DateCreated
    from dbo.Credits c2
    where c2.UserId = c.UserId
        and c2.Status not in (5, 8)
        and right(c2.DogovorNumber, 3) = '002'
) c2
where cast(c.DateStarted as date) between '20181101' and '20190121'
    and right(c.DogovorNumber, 3) = '001'
    and c.Status not in (5, 8)