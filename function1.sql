-- DROP FUNCTION public.get_actual_policy(int4, date);

CREATE OR REPLACE FUNCTION public.get_actual_policy(patient_id integer, search_date date DEFAULT CURRENT_DATE)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    policy_id INT;
BEGIN
    SELECT d.id INTO policy_id
    FROM document d
    JOIN document_type dt ON d.type_fk = dt.id
    JOIN document_category dc ON dt.category_fk = dc.id
    WHERE d.patient_fk = patient_id
      AND dc.code = 'INSURANCE'
      AND d.date_open <= search_date
      AND (d.date_close IS NULL OR d.date_close >= search_date)
    ORDER BY dt.priority ASC
    LIMIT 1;
    
    RETURN policy_id;
END;
$function$
;
