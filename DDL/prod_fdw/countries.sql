CREATE FOREIGN TABLE PROD_FDW.COUNTRIES
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        NAME varchar(255) OPTIONS (column_name 'name'),
        ISO varchar(255) OPTIONS (column_name 'iso'),
        ISO3 varchar(255) OPTIONS (column_name 'iso3'),
        "currencyId" integer OPTIONS (column_name 'currencyId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        AVATAR varchar(255) OPTIONS (column_name 'avatar')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'countries');

ALTER FOREIGN TABLE PROD_FDW.COUNTRIES
    OWNER TO POSTGRES;

