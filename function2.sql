--Создать функцию, заполняющую таблицу с данными пациентов (их персональными данными и данными медицинских случаев). 
--Один входной параметр: УИ счета.
CREATE OR REPLACE FUNCTION public.fill_accounts_data_2(accounts_id integer)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE 
    a_medical_org INT;
    a_departments INT[];
    a_date_open DATE;
    a_date_close DATE;
    rec RECORD;
    is_child_department BOOLEAN;
    current_dept_id INT;
    parent_dept_id INT;
    found BOOLEAN;
    policy_id INT;
    full_name TEXT;
    age INT;
BEGIN
    -- 1. Создаем временную таблицу
    CREATE TEMP TABLE temp_accounts_data (LIKE accounts_data);

    -- 2. Получаем данные счета
    SELECT med_org_fk, departments, date_open, date_close
    INTO a_medical_org, a_departments, a_date_open, a_date_close
    FROM accounts
    WHERE id = accounts_id;

    -- 3. Заполняем временную таблицу данными медицинских случаев (поля 1-8)
    INSERT INTO temp_accounts_data (
        accounts_fk, case_id_fk, case_card_number, case_date_open, case_date_close,
        case_medical_organization, case_department, patient_id, is_filtered, filter_reason
    )
    SELECT 
        accounts_id, mc.id, mc.card_number, mc.date_open, mc.date_close,
        mc.med_org_fk, mc.department_fk, mc.patient_fk, FALSE, NULL
    FROM medical_case mc
    WHERE mc.med_org_fk = a_medical_org
      AND mc.date_close BETWEEN a_date_open AND a_date_close;

    -- 4. Отсев по отделениям
    FOR rec IN SELECT * FROM temp_accounts_data WHERE NOT is_filtered LOOP
        -- Проверяем вхождение в массиве
        IF rec.case_department = ANY(a_departments) THEN
            is_child_department := TRUE;
        ELSE
            -- Проверяем иерархию отделений
            current_dept_id := rec.case_department;
            found := FALSE;
            
            WHILE current_dept_id IS NOT NULL AND NOT found LOOP
                IF current_dept_id = ANY(a_departments) THEN
                    found := TRUE;
                ELSE
                    SELECT parent_department_fk INTO parent_dept_id
                    FROM department 
                    WHERE id = current_dept_id;
                    
                    current_dept_id := parent_dept_id;
                END IF;
            END LOOP;
            
            is_child_department := found;
        END IF;
        
        IF NOT is_child_department THEN
            UPDATE temp_accounts_data
            SET is_filtered = TRUE,
                filter_reason = 'Отделение случая не указано в счете и не является дочерним'
            WHERE case_id_fk = rec.case_id_fk;
        END IF;
    END LOOP;

    -- 5. Заполняем данные пациента (поля 9-11)
    FOR rec IN SELECT * FROM temp_accounts_data WHERE NOT is_filtered LOOP
        SELECT 
            TRIM(TRAILING FROM p.first_name || ' ' || p.last_name || ' ' || COALESCE(p.middle_name, '')),
            p.birth_date,
            EXTRACT(YEAR FROM AGE(mc.date_open, p.birth_date))::INT
        INTO full_name, rec.patient_birth_date, age
        FROM patient p 
        JOIN medical_case mc ON mc.id = rec.case_id_fk
        WHERE p.id = rec.patient_id;
        
        UPDATE temp_accounts_data
        SET 
            patient_full_name = full_name,
            patient_birth_date = rec.patient_birth_date,
            patient_age = age
        WHERE case_id_fk = rec.case_id_fk;
    END LOOP;

    -- 6. Заполняем поле 12 (УИ документа полиса)
    FOR rec IN SELECT * FROM temp_accounts_data WHERE NOT is_filtered LOOP
        policy_id := get_actual_policy(rec.patient_id, rec.case_date_open);
        
        UPDATE temp_accounts_data
        SET document_id = policy_id
        WHERE case_id_fk = rec.case_id_fk;
    END LOOP;

    -- 7. Отсев по отсутствию полиса
    FOR rec IN SELECT * FROM temp_accounts_data WHERE NOT is_filtered LOOP
        IF rec.document_id IS NULL THEN
            UPDATE temp_accounts_data
            SET 
                is_filtered = TRUE,
                filter_reason = 'Не удалось определить актуальный полис на дату открытия случая'
            WHERE case_id_fk = rec.case_id_fk;
        END IF;
    END LOOP;

    -- 8. Заполняем поля 13-15 (данные полиса)
    FOR rec IN SELECT * FROM temp_accounts_data WHERE NOT is_filtered AND document_id IS NOT NULL LOOP
        UPDATE temp_accounts_data
        SET 
            document_type_code = dt.code,
            document_series = d.series,
            document_number = d.number
        FROM document d
        JOIN document_type dt ON d.type_fk = dt.id
        WHERE d.id = rec.document_id
          AND case_id_fk = rec.case_id_fk;
    END LOOP;
    
    -- Вставляем данные в основную таблицу
    INSERT INTO accounts_data
    SELECT * FROM temp_accounts_data;

    -- Удаляем временную таблицу
    DROP TABLE temp_accounts_data_2;
END;
$function$;
