select rf.* -- update rf set rf.Factor = 0
from mkt.PromoCodes pc
inner join mkt.ReductionFactor rf on rf.Id = pc.Id
where pc.Code = 'BPCK'