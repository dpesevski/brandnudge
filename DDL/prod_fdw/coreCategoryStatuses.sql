CREATE FOREIGN TABLE PROD_FDW."coreCategoryStatuses"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "coreCategoryId" integer OPTIONS (column_name 'coreCategoryId') NOT NULL,
        SUBSCRIPTION boolean OPTIONS (column_name 'subscription') NOT NULL,
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'coreCategoryStatuses');

ALTER FOREIGN TABLE PROD_FDW."coreCategoryStatuses"
    OWNER TO POSTGRES;

