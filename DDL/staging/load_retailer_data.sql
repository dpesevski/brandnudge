CREATE FUNCTION STAGING.LOAD_RETAILER_DATA(fetched_data json, flag text DEFAULT NULL::text) RETURNS integer
    LANGUAGE PLPGSQL
AS
$$
DECLARE
    _sql_state TEXT;
    _message   TEXT;
    _detail    TEXT;
    _hint      TEXT;
    _context   TEXT;
    _load_id   integer;
    _start_ts  timestamptz;
BEGIN

    INSERT INTO staging.retailer_daily_data (fetched_data, flag)
    VALUES (fetched_data, flag)
    RETURNING load_id INTO _load_id;

    _start_ts := CLOCK_TIMESTAMP();
    /*IF flag = 'create-products' THEN

        IF JSON_TYPEOF(fetched_data) = 'array' THEN
            RAISE EXCEPTION 'old create-products structure, with no retailer object';
        ELSE
            PERFORM staging.load_retailer_data_base(fetched_data, _load_id);
        END IF;
    ELSEIF flag = 'create-products-pp' THEN*/
    IF flag = 'create-products-pp' THEN
        PERFORM staging.load_retailer_data_pp(fetched_data, _load_id);
    ELSE
        RAISE EXCEPTION 'no valid flag provided';
    END IF;

    UPDATE staging.load
    SET execution_time=ROUND((EXTRACT(EPOCH FROM CLOCK_TIMESTAMP()) - EXTRACT(EPOCH FROM _start_ts))::numeric,
                             2) -- in seconds
    WHERE id = _load_id;

    RETURN _load_id;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sql_state := RETURNED_SQLSTATE,
            _message := MESSAGE_TEXT,
            _detail := PG_EXCEPTION_DETAIL,
            _hint := PG_EXCEPTION_HINT,
            _context := PG_EXCEPTION_CONTEXT;

        INSERT INTO staging.debug_errors (load_id, sql_state, message, detail, hint, context, fetched_data,
                                          flag)
        VALUES (_load_id, _sql_state, _message, _detail, _hint, _context, fetched_data, flag);
        RETURN -1 * _load_id;
END
$$;

ALTER FUNCTION STAGING.LOAD_RETAILER_DATA(JSON, text) OWNER TO POSTGRES;

