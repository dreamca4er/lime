with ValuesTypes as 
(
    select *
    from
    (
        values
        (1, N'Текущие значения')
        , (2, N'Исторические значения')
    ) v(Id, Name)
)
select
    'Borneo' as DBName
    , 'prd.ProductSetting' as TableName
    , N'Продуктовые настройки' as TableDescription
    , vt.Id as TableType
    , vt.Name as TableTypeName
    , SettingType as SettingId
    , isnull(eps.Description, eps.Name) as SettingName
    , ps.ValueSnapshot
from "BOR-LIME-N2-DB".Borneo.prd.ProductSetting ps
left join "BOR-LIME-N2-DB".Borneo.prd.EnumProductSetting eps on eps.id = ps.SettingType
left join ValuesTypes vt on vt.Id = 2
where not exists
    (
        select 1 from "BOR-LIME-N2-DB".Borneo.prd.ProductSetting ps2
        where ps2.SettingType = ps.SettingType
            and ps2.Started > ps.Started
    )

