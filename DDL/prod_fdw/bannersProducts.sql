CREATE FOREIGN TABLE PROD_FDW."bannersProducts"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "productId" integer OPTIONS (column_name 'productId'),
        "bannerId" integer OPTIONS (column_name 'bannerId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        "coreRetailerId" integer OPTIONS (column_name 'coreRetailerId')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'bannersProducts');

ALTER FOREIGN TABLE PROD_FDW."bannersProducts"
    OWNER TO POSTGRES;

