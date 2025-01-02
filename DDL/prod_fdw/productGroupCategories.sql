CREATE FOREIGN TABLE PROD_FDW."productGroupCategories"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "productGroupId" integer OPTIONS (column_name 'productGroupId'),
        "categoryId" integer OPTIONS (column_name 'categoryId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'productGroupCategories');

ALTER FOREIGN TABLE PROD_FDW."productGroupCategories"
    OWNER TO POSTGRES;

