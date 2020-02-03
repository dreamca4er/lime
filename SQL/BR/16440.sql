declare @MinVersion bigint
;
    
select @MinVersion = 
    case ProjectID
        when 2 then 193462214
        when 1 then 27042241
        when 0 then 91460710
    end
from bi.ProjectConfig
;

declare
    @dateFrom date = '20191201'
    , @dateTo date = '20200101'
;
while @dateFrom != '20200301'
begin

declare
    @LastTranslationChange Timestamp = (select max(Timestamp) from bi.Transliteration)
    , @LastNamePartsChange Timestamp
;
if object_id('bi.TranslatedNameParts') is not null
    set @LastNamePartsChange = (select max(Timestamp) from bi.TranslatedNameParts)
;

if object_id('bi.TranslatedNameParts') is null
    or @LastTranslationChange > isnull(@LastNamePartsChange, @LastTranslationChange) 
begin
    drop table if exists bi.TranslatedNameParts
    create table bi.TranslatedNameParts
    (
        id int identity(1,1)
        , NamePart nvarchar(200) not null
        , Translation nvarchar(200)
        , Timestamp timestamp
        , constraint PK_bi_TranslatedNameParts primary key(NamePart, Translation)
    )
end

drop table if exists #check
select
    pay.Id as PaymentId
    , pay.CreatedOn
    , pay.ProcessedOn
    , choose(pay.PaymentDirection, N'Выдача', N'Погашение') as PaymentDirection
    , pay.ContractNumber
    , cc.NumberMasked
    , cast(replace(replace(replace(rtrim(ltrim(cc.Holder))
            , ' ', '<>')
            , '><', '')
            , '<>', ' ') as nvarchar(100)) as Holder
    , cc.ClientId
    , cast(c.FirstName as nvarchar(100)) as FirstName
    , cast(c.LastName as nvarchar(100)) as LastName
into #check
from pmt.vw_Payment pay
inner join pmt.CreditCardPaymentInfo ccpi on ccpi.PaymentId = pay.Id
inner join client.CreditCard cc on cc.Id = ccpi.CreditCardId
outer apply
(
    select top 1 ccl.FirstName, ccl.LastName
    from client.ClientCardLog ccl
    where ccl.ClientId = cc.ClientId
        and ccl.CreatedOn < pay.CreatedOn
    order by ccl.CreatedOn desc
) c
where pay.PaymentWay = 1
    and pay.PaymentStatus = 5
    and cast(pay.CreatedOn as date) >= @dateFrom
    and cast(pay.CreatedOn as date) < @dateTo
    and not exists
    (
        select 1
        from changetable(changes pmt.payment, @MinVersion) ct
        where ct.Id = pay.Id
    )
;

create clustered index IX_check_Names on #check(Holder, FirstName, LastName)
;

drop table if exists #Nameparts
create table #Nameparts 
(
    Namepart nvarchar(200) not null
    , Num bigint
    , Letter nvarchar
    , constraint PK_Nameparts primary key(Namepart, Num)
)
;

with fn as (select distinct FirstName from #check)

,sn as (select distinct LastName from #check)

insert #Nameparts
select
    c.FirstName
    , n.Num
    , let.Letter
from fn c
outer apply
(
    select len(c.FirstName) as FirstNameLen
) L
outer apply
(
    select top (L.FirstNameLen) row_number() over (order by 1/0) as Num
    from sys.objects
) n
outer apply
(
    select substring(c.FirstName, n.Num, 1) as Letter
) let
where not exists
    (
        select 1 from bi.TranslatedNameParts tn
        where tn.Namepart = c.FirstName
    )
    and c.FirstName is not null

union

select
    c.LastName
    , n.Num
    , let.Letter
from sn c
outer apply
(
    select len(c.LastName) as LastNameLen
) L
outer apply
(
    select top (L.LastNameLen) row_number() over (order by 1/0) as Num
    from sys.objects
) n
outer apply
(
    select substring(c.LastName, n.Num, 1) as Letter
) let
where not exists
    (
        select 1 from bi.TranslatedNameParts tn
        where tn.Namepart = c.LastName
    )
    and c.LastName is not null
;

with cte(NamePart, Num, Translation) as 
(
    select
        let.NamePart
        , let.Num
        , cast(tr.Latin as nvarchar(100)) as Translation
    from #NameParts let
    inner join bi.Transliteration tr on tr.Cyrillic = let.Letter
    where let.Num = 1
    
    union all
    
    select
        let.NamePart
        , let.Num
        , cast(Translation + tr.Latin as nvarchar(100)) as Translation
    from cte
    inner join #Nameparts let on cte.Num + 1 = let.Num
        and let.NamePart = cte.NamePart
    inner join bi.Transliteration tr on tr.Cyrillic = let.Letter
    where exists
        (
            select 1 from #Nameparts let2
            where let2.NamePart = cte.NamePart
                and let2.Num = cte.Num + 1
        )
)

insert bi.TranslatedNameParts
(
    NamePart, Translation
)
select
    NamePart
    , Translation    
from cte
where not exists
    (
        select 1 from cte cte2
        where cte2.NamePart = cte.NamePart
            and cte2.Num > cte.Num
    )
;

drop table if exists #fails
select *
into #fails
from #check
where len(replace(holder, ' ', '')) != len(holder) - 1
    or holder not like '%[a-Z] [a-Z]%'
;

delete from #check where Holder in (select holder from #fails)
;

drop table if exists #distinct
select distinct 
    Holder
    , h.*
    , FirstName
    , LastName
into #distinct
from #check c
outer apply (select charindex(' ', holder) as SpaceLoc, len(Holder) as HolderLen) sl
outer apply
(
    select 
        substring(c.Holder, 1, nullif(SpaceLoc - 1, -1)) as NamePart1
        , substring(c.Holder, SpaceLoc + 1, HolderLen - SpaceLoc) as NamePart2
) h
;

create clustered index IX_distinct on  #distinct(Holder, FirstName, LastName)
;

drop table if exists #CheckResult
select
    c.Holder
    , c.FirstName
    , c.Lastname
    , np.Translation as FirstnameTranslation
    , np2.Translation as LastnameTranslation
    , ch.*
into #CheckResult
from #distinct c
left join bi.TranslatedNameParts np on np.NamePart = c.Firstname
left join bi.TranslatedNameParts np2 on np2.NamePart = c.LastName
outer apply
(
    select
        bi.sf_Levenshtein(NamePart1, np.Translation, 100) as CheckAA
        , bi.sf_Levenshtein(NamePart2, np2.Translation, 100) as CheckAB
        , bi.sf_Levenshtein(NamePart2, np.Translation, 100) as CheckBA
        , bi.sf_Levenshtein(NamePart1, np2.Translation, 100) as CheckBB
) as ch
;

declare
    @MaxDistance int = 0
;

with a as 
(
    select 
        cr.*
        , ls.*
        , row_number() over (partition by cr.Holder, cr.FirstName, cr.LastName 
            order by ls.LevenshteinSum) as Rn
    from #CheckResult cr
    outer apply
    (
        select 
            iif(cr.CheckAA + cr.CheckAB < cr.CheckBA + cr.CheckBB
                , cr.CheckAA + cr.CheckAB
                , cr.CheckBA + cr.CheckBB) as LevenshteinSum
            , iif(cr.CheckAA + cr.CheckAB < cr.CheckBA + cr.CheckBB
                , cr.CheckAA
                , cr.CheckBA) as FirstCheck
            , iif(cr.CheckAA + cr.CheckAB < cr.CheckBA + cr.CheckBB
                , cr.CheckAB
                , cr.CheckBB) as SecondCheck
    ) ls
)

,d as 
(
    select
        c.PaymentId
        , c.CreatedOn
        , c.ProcessedOn
        , c.PaymentDirection
        , c.ContractNumber
        , c.NumberMasked
        , a.Holder
        , c.ClientId
        , a.FirstName
        , a.Lastname
        , a.FirstnameTranslation
        , a.LastnameTranslation
        , a.FirstCheck
        , a.SecondCheck
    from a
    inner join #check c on c.Holder = a.Holder
        and c.FirstName = a.FirstName
        and c.Lastname = a.Lastname
    where rn = 1
        and
        (
            FirstCheck > @MaxDistance
            or SecondCheck > @MaxDistance
        )
    
    union all
    
    select *, null, null, null, null
    from #fails
)

insert [bi].[CardPaymentsHolderCheck]
select *
from d

    set @dateFrom = dateadd(month, 1, @dateFrom)
    set @dateTo = dateadd(month, 1, @dateFrom)
end
/

select
    dateadd(month, datediff(month, cast('19000101' as datetime), CreatedOn), cast('19000101' as datetime))
    , count(distinct datepart(dd, CreatedOn))
from[bi].[CardPaymentsHolderCheck]
group by dateadd(month, datediff(month, cast('19000101' as datetime), CreatedOn), cast('19000101' as datetime))