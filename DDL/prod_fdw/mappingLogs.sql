CREATE FOREIGN TABLE PROD_FDW."mappingLogs"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        LOG JSON OPTIONS (column_name 'log'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        MANUAL boolean OPTIONS (column_name 'manual')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'mappingLogs');

ALTER FOREIGN TABLE PROD_FDW."mappingLogs"
    OWNER TO POSTGRES;

