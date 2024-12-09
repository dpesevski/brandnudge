CREATE TABLE staging.load
(
    id             serial,
    data           json,
    flag           text,
    run_at         timestamp DEFAULT NOW(),
    dd_date        date,
    dd_retailer    retailers,
    dd_date_id     integer,
    dd_source_type text,
    execution_time double precision
);

ALTER TABLE staging.load
    OWNER TO postgres;

GRANT SELECT ON staging.load TO bn_ro;

GRANT SELECT ON staging.load TO dejan_user;

