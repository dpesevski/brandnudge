CREATE FOREIGN TABLE PROD_FDW.OTPS
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "userId" integer OPTIONS (column_name 'userId'),
        OPERATION varchar(255) OPTIONS (column_name 'operation'),
        CODE varchar(255) OPTIONS (column_name 'code'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'otps');

ALTER FOREIGN TABLE PROD_FDW.OTPS
    OWNER TO POSTGRES;

