CREATE TABLE STAGING.DEBUG_COREPRODUCTBARCODES
(
    ID              integer                  NOT NULL,
    "coreProductId" integer,
    BARCODE         varchar(255),
    "createdAt"     timestamp with time zone NOT NULL,
    "updatedAt"     timestamp with time zone NOT NULL,
    LOAD_ID         integer
);

ALTER TABLE STAGING.DEBUG_COREPRODUCTBARCODES
    OWNER TO POSTGRES;

GRANT SELECT ON STAGING.DEBUG_COREPRODUCTBARCODES TO BN_RO;

GRANT SELECT ON STAGING.DEBUG_COREPRODUCTBARCODES TO DEJAN_USER;

