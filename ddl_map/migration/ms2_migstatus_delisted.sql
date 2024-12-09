CREATE TABLE migration.ms2_migstatus_delisted
(
    "retailerId"    integer NOT NULL,
    "coreProductId" integer NOT NULL,
    delisted_date   date    NOT NULL,
    CONSTRAINT migstatus_delisted_pk
        PRIMARY KEY (delisted_date, "coreProductId", "retailerId")
);

ALTER TABLE migration.ms2_migstatus_delisted
    OWNER TO postgres;

GRANT SELECT ON migration.ms2_migstatus_delisted TO bn_ro;

GRANT SELECT ON migration.ms2_migstatus_delisted TO dejan_user;

