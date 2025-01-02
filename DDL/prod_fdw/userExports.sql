CREATE FOREIGN TABLE PROD_FDW."userExports"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "userId" integer OPTIONS (column_name 'userId'),
        NAME varchar(255) OPTIONS (column_name 'name'),
        FILENAME varchar(255) OPTIONS (column_name 'filename') NOT NULL,
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        DATA JSONB OPTIONS (column_name 'data') NOT NULL,
        SECTION text OPTIONS (column_name 'section'),
        "scheduledExportId" integer OPTIONS (column_name 'scheduledExportId')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'userExports');

ALTER FOREIGN TABLE PROD_FDW."userExports"
    OWNER TO POSTGRES;

