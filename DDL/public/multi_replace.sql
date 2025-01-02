CREATE FUNCTION MULTI_REPLACE(value text, VARIADIC arr text[]) RETURNS text
    LANGUAGE PLPGSQL
AS
$$
DECLARE
    e         text;
    find_text text;
BEGIN
    BEGIN
        FOREACH e IN ARRAY arr
            LOOP
                IF find_text IS NULL THEN
                    find_text := e;
                ELSE
                    value := REPLACE(value, find_text, e);
                    find_text := NULL;
                END IF;
            END LOOP;

        RETURN value;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
END;
$$;

ALTER FUNCTION MULTI_REPLACE(text, text[]) OWNER TO POSTGRES;

