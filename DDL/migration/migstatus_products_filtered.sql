CREATE TABLE MIGRATION.MIGSTATUS_PRODUCTS_FILTERED
(
    "retailerId"    integer,
    "coreProductId" integer,
    LOAD_DATE       date,
    "productId"     integer
);

ALTER TABLE MIGRATION.MIGSTATUS_PRODUCTS_FILTERED
    OWNER TO POSTGRES;

CREATE INDEX MIGSTATUS_PRODUCTS_FILTERED_RETAILERID_COREPRODUCTID_DATE_INDEX
    ON MIGRATION.MIGSTATUS_PRODUCTS_FILTERED ("retailerId", "coreProductId", LOAD_DATE);

GRANT SELECT ON MIGRATION.MIGSTATUS_PRODUCTS_FILTERED TO BN_RO;

GRANT SELECT ON MIGRATION.MIGSTATUS_PRODUCTS_FILTERED TO DEJAN_USER;

