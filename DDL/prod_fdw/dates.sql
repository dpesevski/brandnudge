CREATE FOREIGN TABLE PROD_FDW.DATES
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        DATE timestamp with time zone OPTIONS (column_name 'date'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt'),
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'dates');

ALTER FOREIGN TABLE PROD_FDW.DATES
    OWNER TO POSTGRES;

