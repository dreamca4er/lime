declare
    @Code nvarchar(6) = '525974'
;
/*
insert client.LockedBinCode (Code)
select @Code
except
select Code
from client.LockedBinCode
where Code = @Code
*/

select
    rt.Description as CardRestrictionName
    , cc.CardRestriction
    , ts.Description as CardTokenStateName
    , tok.CardTokenState
--update tok set CardTokenState = 2
--update cc set CardRestriction = 1
from client.CreditCard cc
left join client.EnumCardRestrictionType rt on rt.id = cc.CardRestriction
left join client.RecurringToken tok on tok.CardId = cc.id
left join client.EnumCardTokenState ts on ts.Id = tok.CardTokenState
where cc.NumberMasked like @Code + '%'