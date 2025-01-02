CREATE FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_CORERETAILERDATES
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "coreRetailerId" integer OPTIONS (column_name 'coreRetailerId'),
        "dateId" integer OPTIONS (column_name 'dateId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        LOAD_ID integer OPTIONS (column_name 'load_id')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'staging', table_name 'debug_coreretailerdates');

ALTER FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_CORERETAILERDATES
    OWNER TO POSTGRES;

