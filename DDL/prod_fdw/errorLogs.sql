CREATE FOREIGN TABLE PROD_FDW."errorLogs"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        MESSAGE text OPTIONS (column_name 'message'),
        STACK text OPTIONS (column_name 'stack'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'errorLogs');

ALTER FOREIGN TABLE PROD_FDW."errorLogs"
    OWNER TO POSTGRES;

