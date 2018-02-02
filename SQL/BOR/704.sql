select
    pay.OrderDescription
    
from pmt.Payment pay
inner join prd.Product pro on pro.ContractNumber = pay.ContractIdentifier
inner join prd.ShortTermCredit stc on stc.Id = pro.id
cross apply
(
    select top 1 stsl.Status
    from prd.ShortTermStatusLog stsl
    where stsl.Product_Id = pro.Id
    order by stsl.StartedOn desc
) stsl
left join pmt.BankAccountPaymentInfo bapi on bapi.PaymentId = pay.id
where pay.PaymentStatus = 4
    and stsl.Status = 2
--group by pay.PaymentStatus, stsl.status, pay.PaymentWay
--order by id desc
/
select *
from pmt.EnumPaymentDirection
/
-- Платежи
 Id     Name       Description        
 -----  ---------  ------------------ 
 0      Undefined  Не определён       
 1      Created    Создан             
 2      Fail       Ошибка             
 3      Success    Успешный           
 4      NeedCheck  Требуется проверка 
 5      Accounted  Проведён           
 6      Declined   Отклонен           


-- Продукты
 Id     EnumId     Name          Description          ProductType    
 -----  ---------  ------------  -------------------  -------------- 
 1000   0          Created       Создан               1              
 1001   1          Canceled      Отменён              1              
 1002   2          NotConfirmed  Не подтверждён       1              
 1003   3          Active        Активен              1              
 1004   4          Overdue       Просрочен            1              
 1005   5          Repaid        Погашен              1              
 1006   6          OnCession     На цессии            1              
 1007   7          OnRestruct    На реструктуризации  1              
 2000   0          Created       Создан               2              
 2001   1          Canceled      Отменён              2              
 2002   2          NotConfirmed  Не подтверждён       2              
 2003   3          Active        Активен              2              
 2004   4          Overdue       Просрочен            2              
 2005   5          Repaid        Погашен              2              
 2006   6          OnCession     На цессии            2              
/
select *
from pmt.EnumPaymentWay
/

select *
from prd.ProductOperation

select *
from client.UserStatusHistory