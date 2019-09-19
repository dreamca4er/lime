with t as 
(
    select
        PayDayOffset * -1 as PayDayOffset
        , Template
    from 
    (
        values
        (3, N'{{io}}, у Вас образовалась просроченная задолженность. Вам необходимо погасить текущий долг. Ваш {{CreditorCompany}} {{CreditorPhone}}')
        , (5, N'{{io}}, зафиксировано нарушение обязательств по Вашему договору займа, образовалась просроченная задолженность. С уважением, {{CreditorCompany}} {{CreditorPhone}}')
        , (6, N'{{io}}, по Вашему займу не поступил платеж, образовалась просроченная задолженность, поэтому Вам был начислен штраф. СРОЧНО перезвоните по номеру {{CreditorPhone}} {{CreditorCompany}}')
        , (8, N'{{io}}, у Вас возникла просроченная задолженность. В соответствии со ст. 309 ГК РФ, настоятельно рекомендуем исполнять добровольно взятые на себя обязательства надлежащим образом {{CreditorPhone}} {{CreditorCompany}}')
        , (11, N'{{io}}, у Вас возникла просроченная задолженность. Настоятельно рекомендуем исполнять добровольно взятые на себя обязательства надлежащим образом {{CreditorPhone}} {{CreditorCompany}}')
        , (13, N'{{io}}, в связи с наличием просроченной задолженности Ваш договор может быть передан в коллекторское агентство {{CreditorPhone}} {{CreditorCompany}}')
        , (15, N'{{io}}, зафиксировано нарушение обязательств по Вашему договору займа, образовалась просроченная задолженность. С уважением, {{CreditorCompany}} {{CreditorPhone}}')
        , (18, N'{{io}}, {{CreditorCompany}} {{CreditorPhone}} требует погасить Вашу просроченную задолженность!')
        , (20, N'{{io}}, у Вас возникла просроченная задолженность, во избежание начисления штрафа настоятельно рекомендуем погасить долг как можно скорее. {{CreditorPhone}} {{CreditorCompany}}')
        , (22, N'{{io}}, во избежание негативных последствий, предусмотренных действующим законодательством, требуем оплатить образовавшуюся просроченную задолженность! {{CreditorPhone}} {{CreditorCompany}}')
        , (26, N'{{io}}, у Вас возникла просроченная задолженность. В соответствии со ст. 309 ГК РФ, настоятельно рекомендуем исполнять добровольно взятые на себя обязательства надлежащим образом {{CreditorPhone}} {{CreditorCompany}}')
        , (28, N'{{io}}, во избежание негативных последствий, предусмотренных действующим законодательством, требуем оплатить образовавшуюся просроченную задолженность! {{CreditorPhone}} {{CreditorCompany}}')
        , (30, N'{{io}}, {{CreditorCompany}} {{CreditorPhone}} требует погасить Вашу просроченную задолженность!')
        , (31, N'{{io}}, Ваше уклонение от оплаты просроченной задолженности организация может рассматривать как отказ от сотрудничества и исполнения обязательств. В Ваших интересах погасить долг в ближайшие дни! {{CreditorPhone}} {{CreditorCompany}}')
        , (35, N'{{io}}, по Вашей просроченной задолженности настоятельно рекомендуем Вам позвонить по номеру {{CreditorPhone}} {{CreditorCompany}}. Звонок на территории Российской Федерации бесплатный')
        , (38, N'{{io}} Вы еще можете исправить критичную ситуацию по просроченной задолженности по Вашему договору займа связавшись с нами по номеру {{CreditorPhone}} {{CreditorCompany}}')
        , (40, N'{{io}}, по Вашей просроченной задолженности настоятельно рекомендуем Вам позвонить по номеру {{CreditorPhone}} {{CreditorCompany}}. Звонок на территории Российской Федерации бесплатный')
        , (41, N'{{io}}, по Вашему займу 2-ой месяц не поступает платеж, образовалась просроченная задолженность, штрафные санкции были увеличены! СРОЧНО перезвоните по номеру {{CreditorPhone}} {{CreditorCompany}}')
        , (43, N'{{io}}, во избежание негативных последствий, предусмотренных действующим законодательством, требуем оплатить образовавшуюся просроченную задолженность! {{CreditorPhone}} {{CreditorCompany}}')
        , (45, N'{{io}}, у Вас возникла просроченная задолженность. В соответствии со ст. 309 ГК РФ, настоятельно рекомендуем исполнять добровольно взятые на себя обязательства надлежащим образом {{CreditorPhone}} {{CreditorCompany}}')
        , (48, N'{{io}}, Ваше уклонение от оплаты организация может рассматривать как отказ от сотрудничества и исполнения обязательств. В Ваших интересах погасить просроченную задолженность в ближайшие дни! {{CreditorPhone}} {{CreditorCompany}}')
        , (50, N'{{io}}, {{CreditorCompany}} {{CreditorPhone}} требует погасить Вашу просроченную задолженность!')
        , (54, N'{{io}}, требуем незамедлительно погасить Вашу просроченную задолженность! {{CreditorPhone}} {{CreditorCompany}}')
        , (56, N'{{io}}, игнорирование требования организации, а также отсутствие платежей расценивается как намеренный отказ от возврата просроченной задолженности. СРОЧНО свяжитесь с нами по телефону. {{CreditorPhone}} {{CreditorCompany}}')
        , (58, N'{{io}}, Ваше бездействие по погашению просроченной задолженности может привести к тому, что организация начнет принудительные меры взыскания. СРОЧНО перезвоните! {{CreditorPhone}} {{CreditorCompany}}')
        , (59, N'{{io}}, во избежание негативных последствий, предусмотренных действующим законодательством, требуем оплатить образовавшуюся просроченную задолженность.{{CreditorPhone}} {{CreditorCompany}}')
        , (60, N'{{io}}, сегодня крайний срок для оплаты Вашей просроченной задолженности по займу. Это последняя возможность урегулировать ситуацию без серьезных последствий. {{CreditorPhone}} {{CreditorCompany}}')
        , (61, N'{{io}}, уведомляем Вас о том, что в случае неоплаты долга, организация вправе переуступить Вашу просроченную задолженность третьим лицам. Срочно позвоните по телефону. {{CreditorPhone}} {{CreditorCompany}}')
        , (65, N'{{io}}, Ваше бездействие по погашению просроченной задолженности может привести к тому, что организация начнет принудительные меры взыскания. СРОЧНО перезвоните! {{CreditorPhone}} {{CreditorCompany}}')
        , (68, N'{{io}}, если Вы готовы решать вопрос о погашении просроченной задолженности на досудебной стадии, то сегодня у Вас есть последний шанс! {{CreditorPhone}} {{CreditorCompany}}')
        , (71, N'{{io}}, во избежание негативных последствий, предусмотренных действующим законодательством, требуем сегодня оплатить образовавшуюся просроченную задолженность! {{CreditorPhone}} {{CreditorCompany}}')
        , (74, N'Внимание! Организация рассматривает вопрос об инициировании процедуры судебного взыскания долга на имя {{io}}. Вам необходимо в течение 2-х дней произвести оплату просроченной задолженности! {{CreditorPhone}} {{CreditorCompany}} ')
        , (77, N'{{io}}, оплаты просроченной задолженности от Вас до сих пор не поступило. Ваше бездействие может привести к тому, что будет инициирована процедура реализации Вашего имущества! СРОЧНО перезвоните! {{CreditorPhone}} {{CreditorCompany}}')
        , (80, N'{{io}}, по Вашему займу третий месяц не поступает платеж, образовалась просроченная задолженность, в связи с этим штрафные санкции значительно увеличены. Срочно перезвоните по номеру {{CreditorPhone}} {{CreditorCompany}}')
        , (83, N'{{io}}, {{CreditorCompany}} {{CreditorPhone}} требует погасить Вашу просроченную задолженность!')
        , (84, N'{{IO}} на данный момент Компания передала Ваши документы для расчёта итоговой суммы просроченной задолженности в целях дальнейшей передачи в Суд.  Сегодня Вы можете решить данный вопрос во внесудебном порядке, оплатив всю сумму долга до конца рабочего дня {{CreditorPhone}} {{CreditorCompany}}')
        , (85, N'{{io}}, рассматривается вопрос отказа от взыскания ранее начисленных штрафов по Вашей просроченной задолженности. Все подробности по телефону: {{CreditorPhone}} {{CreditorCompany}}')
        , (86, N'{{io}}, сегодня Вы еще можете предотвратить передачу долга по займу в судебное производство, погасив просроченную задолженность. {{CreditorPhone}} {{CreditorCompany}} ')
        , (89, N'{{io}}, Ваше уклонение от оплаты организация может рассматривать как отказ от сотрудничества и исполнения обязательств. В Ваших интересах погасить просроченную задолженность в ближайшие дни! {{CreditorPhone}} {{CreditorCompany}}')
        , (90, N'{{io}}, из-за грубых нарушений договора образовалась просроченная задолженность и к Вам могут быть применены меры принудительного взыскания, имущество может быть реализовано. Сроки решения данного вопроса ограничены {{CreditorPhone}} {{CreditorCompany}}')
    ) t(PayDayOffset, Template)
)

    
--select
--    ct.id
--    , ct.Template
--    , ct.IsActive
--    , cdm.CommunicationType
--    , st.Description as CommunicationTypeName
--    , cdm.TemplateType
--    , cdm.PayDayOffset
--    , t.Template
update ct set ct.Template = t.Template
--into dbo.br13005TemplatesBack
from doc.CommunicationTemplate ct
inner join doc.CommunicationTemplateMetadata cdm on ct.MetadataId = cdm.Id
left join ecc.EnumSmsType st on st.Id = cdm.CommunicationType
left join t on t.PayDayOffset = cdm.PayDayOffset
where cdm.TemplateType in (1, 2)
    and cdm.CommunicationType in (11, 12)
    and ct.Template != isnull(t.Template, '')
--order by cdm.PayDayOffset desc, cdm.CommunicationType

