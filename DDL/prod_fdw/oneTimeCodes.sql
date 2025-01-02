CREATE FOREIGN TABLE PROD_FDW."oneTimeCodes"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "userId" integer OPTIONS (column_name 'userId'),
        CODE varchar(255) OPTIONS (column_name 'code'),
        TYPE varchar(255) OPTIONS (column_name 'type'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'oneTimeCodes');

ALTER FOREIGN TABLE PROD_FDW."oneTimeCodes"
    OWNER TO POSTGRES;

