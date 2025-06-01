CREATE OR REPLACE FUNCTION check_document_uniq()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM document d
        WHERE d.id <> COALESCE(NEW.id, -1)
          AND d.type_fk = NEW.type_fk
          AND d.patient_fk = NEW.patient_fk
          AND (d.series IS NULL AND NEW.series IS NULL OR d.series = NEW.series)
          AND d.number = NEW.number
          AND (
              (d.date_close IS NULL AND NEW.date_close IS NULL) OR
              (d.date_close IS NULL AND NEW.date_close >= d.date_open) OR
              (NEW.date_close IS NULL AND d.date_close >= NEW.date_open) OR
              (d.date_open <= NEW.date_close AND d.date_close >= NEW.date_open)
          )
    ) THEN
        RAISE EXCEPTION 'Документ с такими параметрами уже существует и пересекается по датам действия';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--  триггер
CREATE TRIGGER trg_check_document_uniq
BEFORE INSERT OR UPDATE ON document
FOR EACH ROW EXECUTE FUNCTION check_document_uniq();
