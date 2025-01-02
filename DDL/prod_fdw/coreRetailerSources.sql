CREATE FOREIGN TABLE PROD_FDW."coreRetailerSources"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "coreRetailerId" integer OPTIONS (column_name 'coreRetailerId'),
        "retailerId" integer OPTIONS (column_name 'retailerId'),
        "sourceId" varchar(255) OPTIONS (column_name 'sourceId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt'),
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt'),
        LOAD_ID integer OPTIONS (column_name 'load_id')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'coreRetailerSources');

ALTER FOREIGN TABLE PROD_FDW."coreRetailerSources"
    OWNER TO POSTGRES;

