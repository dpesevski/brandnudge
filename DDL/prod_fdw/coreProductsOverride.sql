CREATE FOREIGN TABLE PROD_FDW."coreProductsOverride"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "coreProductId" integer OPTIONS (column_name 'coreProductId'),
        "retailerId" integer OPTIONS (column_name 'retailerId'),
        "sourceId" varchar(255) OPTIONS (column_name 'sourceId') NOT NULL,
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'coreProductsOverride');

ALTER FOREIGN TABLE PROD_FDW."coreProductsOverride"
    OWNER TO POSTGRES;

