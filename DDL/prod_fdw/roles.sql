CREATE FOREIGN TABLE PROD_FDW.ROLES
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        ROLE_NAME varchar(255) OPTIONS (column_name 'role_name') NOT NULL,
        ACCESS_PAGES JSONB OPTIONS (column_name 'access_pages'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'roles');

ALTER FOREIGN TABLE PROD_FDW.ROLES
    OWNER TO POSTGRES;

