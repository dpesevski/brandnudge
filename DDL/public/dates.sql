CREATE TABLE DATES
(
    ID          serial
        PRIMARY KEY,
    DATE        timestamp with time zone,
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone
);

ALTER TABLE DATES
    OWNER TO POSTGRES;

CREATE UNIQUE INDEX DATES_UQ_KEY
    ON DATES (DATE);

GRANT SELECT ON DATES TO BN_RO;

GRANT SELECT ON DATES TO BN_RO_ROLE;

GRANT SELECT ON DATES TO BN_RO_USER1;

GRANT SELECT ON DATES TO DEJAN_USER;

