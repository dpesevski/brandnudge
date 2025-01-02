CREATE FOREIGN TABLE PROD_FDW."productGroupCoreProducts"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "productGroupId" integer OPTIONS (column_name 'productGroupId'),
        "coreProductId" integer OPTIONS (column_name 'coreProductId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'productGroupCoreProducts');

ALTER FOREIGN TABLE PROD_FDW."productGroupCoreProducts"
    OWNER TO POSTGRES;

