CREATE FUNCTION multi_replace(value text, VARIADIC arr text[]) RETURNS text
    LANGUAGE plpgsql
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

ALTER FUNCTION multi_replace(text, text[]) OWNER TO postgres;

