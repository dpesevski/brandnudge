CREATE TABLE data_corr."backup_coreRetailers_productId"
(
    id          integer,
    "productId" varchar(255)
);

ALTER TABLE data_corr."backup_coreRetailers_productId"
    OWNER TO postgres;

GRANT SELECT ON data_corr."backup_coreRetailers_productId" TO bn_ro;

GRANT SELECT ON data_corr."backup_coreRetailers_productId" TO dejan_user;

