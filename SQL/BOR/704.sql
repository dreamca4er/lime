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
-- �������
 Id     Name       Description        
 -----  ---------  ------------------ 
 0      Undefined  �� ��������       
 1      Created    ������             
 2      Fail       ������             
 3      Success    ��������           
 4      NeedCheck  ��������� �������� 
 5      Accounted  �������           
 6      Declined   ��������           


-- ��������
 Id     EnumId     Name          Description          ProductType    
 -----  ---------  ------------  -------------------  -------------- 
 1000   0          Created       ������               1              
 1001   1          Canceled      ������              1              
 1002   2          NotConfirmed  �� ����������       1              
 1003   3          Active        �������              1              
 1004   4          Overdue       ���������            1              
 1005   5          Repaid        �������              1              
 1006   6          OnCession     �� ������            1              
 1007   7          OnRestruct    �� ����������������  1              
 2000   0          Created       ������               2              
 2001   1          Canceled      ������              2              
 2002   2          NotConfirmed  �� ����������       2              
 2003   3          Active        �������              2              
 2004   4          Overdue       ���������            2              
 2005   5          Repaid        �������              2              
 2006   6          OnCession     �� ������            2              
/
select *
from pmt.EnumPaymentWay
/

select *
from prd.ProductOperation

select *
from client.UserStatusHistory