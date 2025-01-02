CREATE FOREIGN TABLE PROD_FDW."userHistories"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "userId" integer OPTIONS (column_name 'userId'),
        PATH text OPTIONS (column_name 'path'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'userHistories');

ALTER FOREIGN TABLE PROD_FDW."userHistories"
    OWNER TO POSTGRES;

