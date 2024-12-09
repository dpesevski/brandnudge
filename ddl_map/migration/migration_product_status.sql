CREATE TABLE migration.migration_product_status
(
    "productId"     integer,
    id              integer,
    status          varchar(255),
    screenshot      varchar(255),
    "createdAt"     timestamp with time zone,
    "updatedAt"     timestamp with time zone,
    load_id         integer,
    "retailerId"    integer,
    "coreProductId" integer,
    date            date
);

ALTER TABLE migration.migration_product_status
    OWNER TO postgres;

CREATE UNIQUE INDEX migration_product_status_productid_uindex
    ON migration.migration_product_status ("productId");

CREATE INDEX migration_product_status_retailer_coreproduct_date_index
    ON migration.migration_product_status ("retailerId", "coreProductId", date);

CREATE INDEX migration_product_status_status_index
    ON migration.migration_product_status (status);

GRANT SELECT ON migration.migration_product_status TO bn_ro;

GRANT SELECT ON migration.migration_product_status TO dejan_user;

