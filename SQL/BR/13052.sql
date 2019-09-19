select mp.*, md.status
from mts.vw_MintosProduct mp
inner join bi.MintosData md on md.lender_id = mp.ProductId
where not
    (
        mp.ProductStatus = 3 and md.status = 'active'
        or
        mp.ProductStatus in (4, 5, 7) and md.status = 'finished'
    )
    and md.status != 'declined'