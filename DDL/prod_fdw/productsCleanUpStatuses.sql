CREATE FOREIGN TABLE PROD_FDW."productsCleanUpStatuses"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "retailerId" integer OPTIONS (column_name 'retailerId') NOT NULL,
        "retailerName" varchar(255) OPTIONS (column_name 'retailerName') NOT NULL,
        "dateId" integer OPTIONS (column_name 'dateId') NOT NULL,
        DATE timestamp with time zone OPTIONS (column_name 'date') NOT NULL,
        STATUS varchar(255) OPTIONS (column_name 'status') NOT NULL,
        "productsCount" integer OPTIONS (column_name 'productsCount'),
        "completedCount" integer OPTIONS (column_name 'completedCount'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'productsCleanUpStatuses');

ALTER FOREIGN TABLE PROD_FDW."productsCleanUpStatuses"
    OWNER TO POSTGRES;

