-- Создаем триггерную функцию
CREATE OR REPLACE FUNCTION check_department_date_open()
RETURNS TRIGGER AS $$
DECLARE
    org_date_open DATE;
BEGIN
    -- Получаем дату открытия медицинской организации
    SELECT date_open INTO org_date_open
    FROM med_org
    WHERE id = NEW.med_org_fk;
    
    -- Проверяем, что дата открытия отделения не раньше даты открытия организации
    IF NEW.date_open < org_date_open THEN
        RAISE EXCEPTION 'Дата открытия отделения (%) не может быть раньше даты открытия медицинской организации (%)', 
                        NEW.date_open, org_date_open;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Создаем триггер, который срабатывает перед вставкой
CREATE TRIGGER trg_check_department_date_open
BEFORE INSERT ON department
FOR EACH ROW EXECUTE FUNCTION check_department_date_open();
