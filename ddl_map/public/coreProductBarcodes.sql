CREATE TABLE "coreProductBarcodes"
(
    id              serial
        PRIMARY KEY,
    "coreProductId" integer,
    barcode         varchar(255)
        UNIQUE,
    "createdAt"     timestamp with time zone NOT NULL,
    "updatedAt"     timestamp with time zone NOT NULL,
    load_id         integer,
    UNIQUE ("coreProductId", barcode)
);

ALTER TABLE "coreProductBarcodes"
    OWNER TO postgres;

GRANT SELECT ON "coreProductBarcodes" TO bn_ro;

GRANT SELECT ON "coreProductBarcodes" TO bn_ro_role;

GRANT SELECT ON "coreProductBarcodes" TO bn_ro_user1;

GRANT SELECT ON "coreProductBarcodes" TO dejan_user;

