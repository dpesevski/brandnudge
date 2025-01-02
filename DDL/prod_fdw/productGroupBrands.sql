CREATE FOREIGN TABLE PROD_FDW."productGroupBrands"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "productGroupId" integer OPTIONS (column_name 'productGroupId'),
        "brandId" integer OPTIONS (column_name 'brandId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'productGroupBrands');

ALTER FOREIGN TABLE PROD_FDW."productGroupBrands"
    OWNER TO POSTGRES;

