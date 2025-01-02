CREATE TABLE DATA_CORR."backup_coreRetailers_productId"
(
    ID          integer,
    "productId" varchar(255)
);

ALTER TABLE DATA_CORR."backup_coreRetailers_productId"
    OWNER TO POSTGRES;

GRANT SELECT ON DATA_CORR."backup_coreRetailers_productId" TO BN_RO;

GRANT SELECT ON DATA_CORR."backup_coreRetailers_productId" TO DEJAN_USER;

