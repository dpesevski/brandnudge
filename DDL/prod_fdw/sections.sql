CREATE FOREIGN TABLE PROD_FDW.SECTIONS
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        NAME varchar(255) OPTIONS (column_name 'name'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        TITLE varchar(255) OPTIONS (column_name 'title')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'sections');

ALTER FOREIGN TABLE PROD_FDW.SECTIONS
    OWNER TO POSTGRES;

