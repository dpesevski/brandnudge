CREATE FUNCTION fn_to_boolean(value text) RETURNS boolean
    LANGUAGE plpgsql
AS
$$
BEGIN
    BEGIN
        RETURN value::boolean;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
END;
$$;

ALTER FUNCTION fn_to_boolean(text) OWNER TO postgres;

