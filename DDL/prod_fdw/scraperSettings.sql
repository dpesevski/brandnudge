CREATE FOREIGN TABLE PROD_FDW."scraperSettings"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "retailerId" integer OPTIONS (column_name 'retailerId') NOT NULL,
        SETTINGS JSON OPTIONS (column_name 'settings'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'scraperSettings');

ALTER FOREIGN TABLE PROD_FDW."scraperSettings"
    OWNER TO POSTGRES;

