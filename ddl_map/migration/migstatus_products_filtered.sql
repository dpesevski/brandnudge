CREATE TABLE migration.migstatus_products_filtered
(
    "retailerId"    integer,
    "coreProductId" integer,
    load_date       date,
    "productId"     integer
);

ALTER TABLE migration.migstatus_products_filtered
    OWNER TO postgres;

CREATE INDEX migstatus_products_filtered_retailerid_coreproductid_date_index
    ON migration.migstatus_products_filtered ("retailerId", "coreProductId", load_date);

GRANT SELECT ON migration.migstatus_products_filtered TO bn_ro;

GRANT SELECT ON migration.migstatus_products_filtered TO dejan_user;

