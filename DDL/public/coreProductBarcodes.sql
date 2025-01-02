CREATE TABLE "coreProductBarcodes"
(
    ID              serial
        PRIMARY KEY,
    "coreProductId" integer,
    BARCODE         varchar(255)
        UNIQUE,
    "createdAt"     timestamp with time zone NOT NULL,
    "updatedAt"     timestamp with time zone NOT NULL,
    LOAD_ID         integer,
    UNIQUE ("coreProductId", BARCODE)
);

ALTER TABLE "coreProductBarcodes"
    OWNER TO POSTGRES;

GRANT SELECT ON "coreProductBarcodes" TO BN_RO;

GRANT SELECT ON "coreProductBarcodes" TO BN_RO_ROLE;

GRANT SELECT ON "coreProductBarcodes" TO BN_RO_USER1;

GRANT SELECT ON "coreProductBarcodes" TO DEJAN_USER;

