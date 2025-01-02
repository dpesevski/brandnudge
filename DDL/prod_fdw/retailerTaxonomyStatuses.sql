CREATE FOREIGN TABLE PROD_FDW."retailerTaxonomyStatuses"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "retailerTaxonomyId" integer OPTIONS (column_name 'retailerTaxonomyId'),
        BANNERS boolean OPTIONS (column_name 'banners'),
        PRODUCTS boolean OPTIONS (column_name 'products'),
        SUBSCRIPTION boolean OPTIONS (column_name 'subscription'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'retailerTaxonomyStatuses');

ALTER FOREIGN TABLE PROD_FDW."retailerTaxonomyStatuses"
    OWNER TO POSTGRES;

