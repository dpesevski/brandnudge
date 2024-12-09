CREATE TABLE migration.ms2_migstatus_last_load_product
(
    "retailerId"    integer,
    "coreProductId" integer,
    delisted_date   date,
    load_date       date
);

ALTER TABLE migration.ms2_migstatus_last_load_product
    OWNER TO postgres;

GRANT SELECT ON migration.ms2_migstatus_last_load_product TO bn_ro;

GRANT SELECT ON migration.ms2_migstatus_last_load_product TO dejan_user;

