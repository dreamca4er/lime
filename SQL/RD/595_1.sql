
ALTER VIEW [bi].[vw_IFRSProduct] as 
with PreOver as 
(
    select
        sl.ProductId
        ,datediff(d, sl.StartedOn, isnull(NextStatus.StartedOn, getdate())) + 1 as OverdueLength
    from prd.vw_statusLog sl
    outer apply
    (
        select min(sl2.StartedOn) as StartedOn
        from prd.vw_statusLog sl2
        where sl2.ProductId = sl.ProductId
            and sl2.StartedOn > sl.StartedOn
    ) NextStatus
    where sl.Status = 4
)

select
    p.Productid
    ,p.ClientId
    ,p.Amount
    ,p.ProductTypeName
    ,p.StartedOn
    ,isnull(ol.MaxOverdueLength, 0) as MaxOverdueLength
    ,case 
        when isnull(ol.MaxOverdueLength, 0) = 0
        then N'Кат 1: 0 дней'
        when isnull(ol.MaxOverdueLength, 0) = 1
        then N'Кат 2: 1 день'
        when isnull(ol.MaxOverdueLength, 0) <= 10
        then N'Кат 3: до 11 дней'
        when isnull(ol.MaxOverdueLength, 0) <= 20
        then N'Кат 4: до 21 дня'
        when isnull(ol.MaxOverdueLength, 0) <= 40
        then N'Кат 5: до 41 дня'
        when isnull(ol.MaxOverdueLength, 0) <= 60
        then N'Кат 6: до 61 дня'
        when isnull(ol.MaxOverdueLength, 0) <= 80
        then N'Кат 7: до 81 дня'
        when isnull(ol.MaxOverdueLength, 0) <= 100
        then N'Кат 8: до 101 дня'
        else N'Кат 9: со 101 дня'
    end as MaxOverdueCategory
    ,p.StatusName as CurrentStatus
    ,isnull(r.HadRestructure, 0) as HadRestructure
    ,c.SexKind
    ,c.MaritalStatusKind
    ,c.ChildrenKind
    ,isnull(c.Income, 0) as Income
    ,case 
        when isnull(c.Income, 0) = 0
        then N'Кат 0: доход не определен'
        when Amount / Income > 0 and Amount / Income < 0.1 then N'Кат 1: до 0.1'
        when Amount / Income >= 0.1 and Amount / Income < 0.2 then N'Кат 2: 0.1-0.2'
        when Amount / Income >= 0.2 and Amount / Income < 0.5 then N'Кат 3: 0.2-0.5'
        when Amount / Income >= 0.5 and Amount / Income < 1 then N'Кат 4: 0.5-1'
        when Amount / Income >= 1 and Amount / Income < 2 then N'Кат 5: 1-2'
        when Amount / Income >= 2 and Amount / Income < 5 then N'Кат 6: 2-5'
        when Amount / Income >= 5 then N'Кат 7: 5+'
    end as AmountToIncome
    ,case 
        when a.AgeAtCreditStart = 0 then N'Кат 0: Не определен'
        when a.AgeAtCreditStart < 27 then N'Кат 1: до 27'
        when a.AgeAtCreditStart >= 27 and a.AgeAtCreditStart < 35 then N'Кат 2: 27-35'
        when a.AgeAtCreditStart >= 35 and a.AgeAtCreditStart < 45 then N'Кат 3: 35-45'
        when a.AgeAtCreditStart >= 45 and a.AgeAtCreditStart < 60 then N'Кат 4: 45-60'
        when a.AgeAtCreditStart >= 60 then N'Кат 5: 60+'
    end as AgeCategory
from prd.vw_product p
inner join client.vw_client c on c.clientid = p.ClientId
outer apply
(
    select max(OverdueLength) as MaxOverdueLength
    from PreOver po
    where po.ProductId = p.ProductId
) ol
outer apply
(
    select count(distinct 1) as HadRestructure
    from prd.vw_statusLog sl
    where sl.ProductId = p.Productid
        and sl.Status = 7
) r
outer apply
(
    select
        case 
            when datepart(year, c.BirthDate) < 1947 then 0
            else datediff(year, c.BirthDate, p.StartedOn) - 
                case when datepart(dayofyear, p.StartedOn) < datepart(dayofyear, c.BirthDate) then 1 else 0 end
        end as AgeAtCreditStart
) a
where p.Status >= 3
    and p.StartedOn < cast(getdate() as date)
GO


