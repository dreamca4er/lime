drop table if exists #p
;

select *
into #p
from
(
    select
        p.ClientId
        ,p.Productid
        ,datediff(d, sl.StartedOn, getdate()) + 1 as OverdueDays
        ,ba.AccountNum
    from prd.vw_product p
    inner join pmt.Payment pay on pay.ContractNumber = p.ContractNumber
        and pay.PaymentDirection = 1
    left join pmt.BankAccountPaymentInfo bapi on bapi.PaymentId = pay.id
    left join client.BankAccount ba on ba.id = bapi.BankAccountId
    outer apply
    (
        select top 1
            sl.StatusName
            ,sl.StartedOn
        from prd.vw_statusLog sl
        where sl.ProductId = p.Productid
        order by sl.StartedOn desc
    ) sl
    where p.PaymentWay = 2
        and p.Status = 4
) p
;

select
    #p.ClientId
    ,#p.Productid
    ,#p.OverdueDays
    ,isnull(#p.AccountNum, ba.AccountNum) as AccountNum
from #p
left join "LIME-DB".LimeZaim_Website.dbo.Credits c on c.id = #p.Productid 
left join "LIME-DB".LimeZaim_Website.dbo.Payments pay on pay.id = c.BorrowPaymentId
left join "LIME-DB".LimeZaim_Website.dbo.BankAccounts ba on ba.Id = pay.BankAccountId
    and ba.UserId = c.UserId

