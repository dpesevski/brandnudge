CREATE FOREIGN TABLE PROD_FDW."userSessions"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "userId" integer OPTIONS (column_name 'userId'),
        ACTION varchar(255) OPTIONS (column_name 'action'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'userSessions');

ALTER FOREIGN TABLE PROD_FDW."userSessions"
    OWNER TO POSTGRES;

