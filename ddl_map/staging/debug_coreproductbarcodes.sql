CREATE TABLE staging.debug_coreproductbarcodes
(
    id              integer                  NOT NULL,
    "coreProductId" integer,
    barcode         varchar(255),
    "createdAt"     timestamp with time zone NOT NULL,
    "updatedAt"     timestamp with time zone NOT NULL,
    load_id         integer
);

ALTER TABLE staging.debug_coreproductbarcodes
    OWNER TO postgres;

GRANT SELECT ON staging.debug_coreproductbarcodes TO bn_ro;

GRANT SELECT ON staging.debug_coreproductbarcodes TO dejan_user;

