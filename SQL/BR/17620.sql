-- stuff.dbo.br17260back
--update n set n.Text = replace(n.Text
--        , substring(n.text, pre.Start, tech.FioLocation - pre.Start + tech.FioLen + 4)
--        , N' Назначение платежа: Цессия МангоФинанс Договор № ' + p.ContractNumber
--            + N' от ' + convert(nvarchar(30), p.CreatedOn, 103)
--            + N' г. ' + pre.fio)
select top 100 n.text
from prd.vw_statusLog sl
inner join ecc.Notice n on n.ProductId = sl.ProductId
    and n.TemplateUuid = 'F387233C-FE4F-4767-90EB-ED05CCD8945A'
inner join prd.Product p on p.Id = sl.ProductId
left join client.Client c on c.Id = n.ClientId
outer apply
(
    select
        patindex(N'% Назначение платежа%Сообщаем о том, %', n.Text) as Start
        , rtrim(concat(c.LastName, ' ', c.FirstName, ' ', c.FatherName)) as fio
) pre
outer apply
(
    select 
        patindex(N'%от ' + pre.fio + '%', n.text) as FioLocation
        , len(pre.fio + '<br>') as FioLen
) tech
where sl.Status = 6
    and sl.StartedOn = '20191231'