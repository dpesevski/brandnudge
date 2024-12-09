CREATE TABLE migration.ms2_migstatus_products_filtered
(
    "retailerId"    integer,
    "coreProductId" integer,
    load_date       date,
    "productId"     integer
);

ALTER TABLE migration.ms2_migstatus_products_filtered
    OWNER TO postgres;

CREATE INDEX ms2_migstatus_products_filtered_retailerid_coreproductid_date_i
    ON migration.ms2_migstatus_products_filtered ("retailerId", "coreProductId", load_date);

GRANT SELECT ON migration.ms2_migstatus_products_filtered TO bn_ro;

GRANT SELECT ON migration.ms2_migstatus_products_filtered TO dejan_user;

