CREATE FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_RETAILERS
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        NAME varchar(255) OPTIONS (column_name 'name'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        COLOR varchar(255) OPTIONS (column_name 'color') NOT NULL,
        LOGO varchar(255) OPTIONS (column_name 'logo'),
        "countryId" integer OPTIONS (column_name 'countryId'),
        LOAD_ID integer OPTIONS (column_name 'load_id')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'staging', table_name 'debug_retailers');

ALTER FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_RETAILERS
    OWNER TO POSTGRES;

