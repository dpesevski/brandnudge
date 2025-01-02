CREATE FOREIGN TABLE PROD_FDW."sharedReports"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "reportId" integer OPTIONS (column_name 'reportId') NOT NULL,
        "userId" integer OPTIONS (column_name 'userId') NOT NULL,
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'sharedReports');

ALTER FOREIGN TABLE PROD_FDW."sharedReports"
    OWNER TO POSTGRES;

