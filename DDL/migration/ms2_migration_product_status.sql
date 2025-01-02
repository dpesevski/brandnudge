CREATE TABLE MIGRATION.MS2_MIGRATION_PRODUCT_STATUS
(
    "productId"     integer,
    ID              integer,
    STATUS          varchar(255),
    SCREENSHOT      varchar(255),
    "createdAt"     timestamp with time zone,
    "updatedAt"     timestamp with time zone,
    LOAD_ID         integer,
    "retailerId"    integer,
    "coreProductId" integer,
    DATE            date
);

ALTER TABLE MIGRATION.MS2_MIGRATION_PRODUCT_STATUS
    OWNER TO POSTGRES;

CREATE UNIQUE INDEX MS2_MIGRATION_PRODUCT_STATUS_PRODUCTID_UINDEX
    ON MIGRATION.MS2_MIGRATION_PRODUCT_STATUS ("productId");

CREATE INDEX MS2_MIGRATION_PRODUCT_STATUS_RETAILER_COREPRODUCT_DATE_INDEX
    ON MIGRATION.MS2_MIGRATION_PRODUCT_STATUS ("retailerId", "coreProductId", DATE);

CREATE INDEX MS2_MIGRATION_PRODUCT_STATUS_STATUS_INDEX
    ON MIGRATION.MS2_MIGRATION_PRODUCT_STATUS (STATUS);

GRANT SELECT ON MIGRATION.MS2_MIGRATION_PRODUCT_STATUS TO BN_RO;

GRANT SELECT ON MIGRATION.MS2_MIGRATION_PRODUCT_STATUS TO DEJAN_USER;

