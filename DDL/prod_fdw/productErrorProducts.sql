CREATE FOREIGN TABLE PROD_FDW."productErrorProducts"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "errorId" integer OPTIONS (column_name 'errorId') NOT NULL,
        "productId" integer OPTIONS (column_name 'productId') NOT NULL,
        RESOLVED boolean OPTIONS (column_name 'resolved') NOT NULL,
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'productErrorProducts');

ALTER FOREIGN TABLE PROD_FDW."productErrorProducts"
    OWNER TO POSTGRES;

