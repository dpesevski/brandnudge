CREATE FOREIGN TABLE PROD_FDW."productStatuses"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "productId" integer OPTIONS (column_name 'productId'),
        STATUS varchar(255) OPTIONS (column_name 'status') NOT NULL,
        SCREENSHOT varchar(255) OPTIONS (column_name 'screenshot'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        LOAD_ID integer OPTIONS (column_name 'load_id')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'productStatuses');

ALTER FOREIGN TABLE PROD_FDW."productStatuses"
    OWNER TO POSTGRES;

