CREATE FOREIGN TABLE PROD_FDW."companyTaxonomies"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "companyId" integer OPTIONS (column_name 'companyId'),
        "retailerTaxonomyId" integer OPTIONS (column_name 'retailerTaxonomyId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'companyTaxonomies');

ALTER FOREIGN TABLE PROD_FDW."companyTaxonomies"
    OWNER TO POSTGRES;

