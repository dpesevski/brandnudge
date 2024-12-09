CREATE TABLE staging.debug_errors
(
    id           serial,
    load_id      integer,
    sql_state    text,
    message      text,
    detail       text,
    hint         text,
    context      text,
    fetched_data json,
    flag         text,
    created_at   timestamp DEFAULT NOW()
);

ALTER TABLE staging.debug_errors
    OWNER TO postgres;

GRANT SELECT ON staging.debug_errors TO bn_ro;

GRANT SELECT ON staging.debug_errors TO dejan_user;

