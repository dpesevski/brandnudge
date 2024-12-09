CREATE TABLE migration.ms2_tmp_mig2nd_product_status_history
(
    "retailerId"    integer,
    "coreProductId" integer,
    date            date,
    "productId"     integer,
    status          text
);

ALTER TABLE migration.ms2_tmp_mig2nd_product_status_history
    OWNER TO postgres;

CREATE INDEX tmp_product_status_history_productid_uindex
    ON migration.ms2_tmp_mig2nd_product_status_history ("productId");

GRANT SELECT ON migration.ms2_tmp_mig2nd_product_status_history TO bn_ro;

GRANT SELECT ON migration.ms2_tmp_mig2nd_product_status_history TO dejan_user;

