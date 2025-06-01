- Добавляем тип кода организации
INSERT INTO organization_code_type (id, name, code, date_open, date_close) 
VALUES (1, 'Код в системе ОМС', 'CODE_OMS', '2000-01-01', NULL);

-- Добавляем коды организаций (на основе существующих мед. организаций)
INSERT INTO organization_code (id, med_org_fk, code_type_fk, value, date_open, date_close)
SELECT 
    row_number() OVER () + 100, -- Генерируем уникальные ID
    id, 
    1, -- CODE_OMS
    code, -- Используем код из таблицы med_org
    date_open, 
    date_close
FROM med_org
WHERE NOT EXISTS (
    SELECT 1 FROM organization_code oc 
    WHERE oc.med_org_fk = med_org.id 
      AND oc.code_type_fk = 1 
      AND oc.value = med_org.code
);
