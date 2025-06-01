-- Таблица типов кодов организаций
CREATE TABLE organization_code_type (
    id INT PRIMARY KEY,
    name TEXT NOT NULL,
    code TEXT NOT NULL,
    date_open DATE NOT NULL,
    date_close DATE
);
-- 1. Сначала создаем функцию для проверки пересечения дат
CREATE OR REPLACE FUNCTION check_organization_code_overlap(
    p_med_org INT,
    p_code_type INT,
    p_date_open DATE,
    p_date_close DATE
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM organization_code
        WHERE med_org_fk = p_med_org
          AND code_type_fk = p_code_type
          AND (
              (date_close IS NULL AND p_date_close IS NULL) OR
              (date_close IS NULL AND p_date_close >= date_open) OR
              (p_date_close IS NULL AND date_close >= p_date_open) OR
              (date_open <= p_date_close AND date_close >= p_date_open)
          )
    );
END;
$$ LANGUAGE plpgsql;

-- 2. Создаем таблицу organization_code сразу с CHECK-ограничением
CREATE TABLE organization_code (
    id INT PRIMARY KEY,
    med_org_fk INT NOT NULL REFERENCES med_org(id),
    code_type_fk INT NOT NULL REFERENCES organization_code_type(id),
    value TEXT NOT NULL,
    date_open DATE NOT NULL,
    date_close DATE,
    CHECK (date_close IS NULL OR date_close >= date_open),
    CONSTRAINT check_code_overlap CHECK (
        NOT check_organization_code_overlap(
            med_org_fk, 
            code_type_fk, 
            date_open, 
            date_close
        )
    )
);