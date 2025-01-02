CREATE TABLE STAGING.LOAD
(
    ID             serial,
    DATA           JSON,
    FLAG           text,
    RUN_AT         timestamp DEFAULT NOW(),
    DD_DATE        date,
    DD_RETAILER    RETAILERS,
    DD_DATE_ID     integer,
    DD_SOURCE_TYPE text,
    EXECUTION_TIME double precision,
    LOAD_STATUS    text
);

ALTER TABLE STAGING.LOAD
    OWNER TO POSTGRES;

GRANT SELECT ON STAGING.LOAD TO BN_RO;

GRANT SELECT ON STAGING.LOAD TO DEJAN_USER;

