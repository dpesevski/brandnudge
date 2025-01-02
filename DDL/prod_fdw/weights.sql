CREATE FOREIGN TABLE PROD_FDW.WEIGHTS
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        NAME varchar(255) OPTIONS (column_name 'name'),
        VALUE text OPTIONS (column_name 'value'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        "userId" integer OPTIONS (column_name 'userId') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'weights');

ALTER FOREIGN TABLE PROD_FDW.WEIGHTS
    OWNER TO POSTGRES;

