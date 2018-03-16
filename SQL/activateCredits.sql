drop table if exists #list
;

select id
into #list
from prd.Product p
where p.id in
    (

    )
;


--select *
update stc
set
    stc.Status = 3   
from prd.ShortTermCredit stc
where id in (select id from #list)

;
insert into prd.ShortTermStatusLog
(
    CreatedOn,CreatedBy,Status,ProductId,StartedOn
)
select
    '20180226 00:01:01' as CreatedOn
    ,cast(0x0 as uniqueidentifier) as CreatedBy
    ,3 as Status
    ,id as ProductId 
    ,'20180226 00:01:01' as StartedOn
from #list

--select StartedOn
update p
set StartedOn = '20180226'
from prd.Product p
where id in (select id from #list)

/

insert into pmt.Payment
(
    Amount,Currency,PaymentDirection,PaymentStatus,PaymentType,PaymentWay,PaymentKind,OrderId,OrderDescription,ContractNumber,CreatedOn,CreatedBy
)


/
select productid, clientid
from prd.vw_Product p
where cast(p.ContractNumber as bigint) < 1900000000
    and p.PaymentWay = 2 
    and p.StartedOn = '20180226'
    and p.status != 1
    and p.productid not in
(
355831
,356161
)
