select
    p.Productid as "Id займа"
    , p.ContractNumber as "Номер договора" 
    , p.StartedOn as "Дата выдачи"
    , p.Amount as "Сумма займа"
    , p.Psk as "ПСК"
    , cast(p.DatePaid as date) as "Дата погашения"
    , sl.StatusName as "Статус займа на 20190424"
    , concat(c.LastName, ' ', c.FirstName, ' ', c.FatherName) as "ФИО заемщика"
from prd.vw_product p
inner join client.Client c on c.id = p.ClientId
outer apply
(
    select top 1 sl.StatusName
    from prd.vw_statusLog sl
    where sl.ProductId = p.Productid
        and cast(sl.StartedOn as date) <= '20190424'
    order by sl.StartedOn desc
) sl
where p.CreatedOn >= '20180101'
    and p.CreatedOn < '20190425'
    
    