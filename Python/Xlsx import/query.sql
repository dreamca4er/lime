select
    d.ClientId
    , d.Fio
    , d.ProductId
    , d.ContractNumber
    , d.CreatedOn
    , d.StartedOn
    , d.Period
    , d.Amount
    , d.InsuranceCost
    , d.AmountWithInsuranceCost
    , d.PayUnderContract
    , d.PercentPerDay
    , d.PaymentWayName
    , d.PSK
    , d.ppt
    , d.TypeFlagName
    , d.LeftAmount
    , d.ActiveAmt
    , d.OverdueAmt
    , d.TotalPct
    , d.ActivePct
    , d.OverduePct
    , d.Commission
    , d.TotalAmount
    , d.TotalPercent
    , d.FixedPercent
    , d.RemissionPercent
    , d.PercentDiscount
    , d.CommissionProductPaid
    , d.Prolong
    , d.CommissionByPaid
    , d.Fine
    , d.Duty
    , d.OverPay
    , d.CurrentStatusName
    , d.CurrentStatusStartedOn
    , d.StatusNameOnEndPeriod
    , d.StatusStartedOnEndPeriod
    , d.OverdueDays
    , d.WasProlonged
    , d.ReserveName
    , d.Pct
    , d.ReserveAmt
    , d.ReservePct
    , d.ReserveCom
from dbo.ReportDetail d
where ReportId = ?ReportId