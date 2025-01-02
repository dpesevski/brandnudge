CREATE FOREIGN TABLE PROD_FDW.CURRENCIES
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        NAME varchar(255) OPTIONS (column_name 'name'),
        ISO varchar(255) OPTIONS (column_name 'iso'),
        SYMBOL varchar(255) OPTIONS (column_name 'symbol'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'currencies');

ALTER FOREIGN TABLE PROD_FDW.CURRENCIES
    OWNER TO POSTGRES;

