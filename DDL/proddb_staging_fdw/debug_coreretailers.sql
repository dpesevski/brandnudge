CREATE FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_CORERETAILERS
    (
        "sourceId" text OPTIONS (column_name 'sourceId'),
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "coreProductId" integer OPTIONS (column_name 'coreProductId'),
        "retailerId" integer OPTIONS (column_name 'retailerId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        LOAD_ID integer OPTIONS (column_name 'load_id')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'staging', table_name 'debug_coreretailers');

ALTER FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_CORERETAILERS
    OWNER TO POSTGRES;

