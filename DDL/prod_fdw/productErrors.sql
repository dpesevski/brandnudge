CREATE FOREIGN TABLE PROD_FDW."productErrors"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "retailerId" integer OPTIONS (column_name 'retailerId') NOT NULL,
        TYPE varchar(255) OPTIONS (column_name 'type') NOT NULL,
        RESOLVED boolean OPTIONS (column_name 'resolved'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'productErrors');

ALTER FOREIGN TABLE PROD_FDW."productErrors"
    OWNER TO POSTGRES;

