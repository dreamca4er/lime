select
    dch.DateCreated as "Дата и время назначения на коллектора"
    ,cu.UserName as "Коллектор"
    ,case 
        when dch.CreatedByUserId = 1 then N'Автомат'
        else u.UserName
    end as "Кто назначил"
    ,fu.Id as "Клиент"
    ,fu.Lastname + ' ' + fu.Firstname + isnull(' ' + fu.Fathername, '') as "ФИО"
    ,datediff(d, cast(csh.DateStarted as date), cast(dch.DateCreated as date)) + 1 as "Дней просрочки"
    ,cb.mainDebt as "Сумма основного долга"
    ,cb.otherdebt as "Сумма прочего долга"
from dbo.DebtorCollectorHistory dch
inner join dbo.Debtors d on d.Id = dch.DebtorId
inner join dbo.Credits c on c.Id = d.CreditId
inner join dbo.FrontendUsers fu on fu.Id = c.UserId
left join CmsContent_LimeZaim.dbo.Users u on u.UserId = dch.CreatedByUserId
left join CmsContent_LimeZaim.dbo.Users cu on cu.UserId = dch.CollectorId
outer apply
(
    select top 1
        csh.DateStarted
    from dbo.CreditStatusHistory csh
    where csh.CreditId = c.id
        and csh.DateStarted <= cast(dch.DateCreated as date)
        and csh.Status = 3
    order by csh.DateStarted desc
) as csh
outer apply
(
    select top 1
        cb.Amount as mainDebt
        ,cb.PercentAmount + cb.CommisionAmount + cb.PenaltyAmount + cb.LongPrice + cb.TransactionCosts as otherDebt
    from dbo.CreditBalances cb
    where cb.CreditId = c.id
        and cb.Amount != 0
        and cb.Date < cast(dch.DateCreated as date)
    order by cb.Date desc
) cb
where cast(dch.DateCreated as date) between '20170825' and '20170825'
