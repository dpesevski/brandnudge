CREATE FOREIGN TABLE PROD_FDW."coreRetailerTaxonomies"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "coreRetailerId" integer OPTIONS (column_name 'coreRetailerId'),
        "retailerTaxonomyId" integer OPTIONS (column_name 'retailerTaxonomyId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        LOAD_ID integer OPTIONS (column_name 'load_id')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'coreRetailerTaxonomies');

ALTER FOREIGN TABLE PROD_FDW."coreRetailerTaxonomies"
    OWNER TO POSTGRES;

