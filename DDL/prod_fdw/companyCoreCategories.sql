CREATE FOREIGN TABLE PROD_FDW."companyCoreCategories"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "companyId" integer OPTIONS (column_name 'companyId'),
        "categoryId" integer OPTIONS (column_name 'categoryId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'companyCoreCategories');

ALTER FOREIGN TABLE PROD_FDW."companyCoreCategories"
    OWNER TO POSTGRES;

