CREATE FOREIGN TABLE PROD_FDW."userCountries"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "userId" integer OPTIONS (column_name 'userId'),
        "countryId" integer OPTIONS (column_name 'countryId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'userCountries');

ALTER FOREIGN TABLE PROD_FDW."userCountries"
    OWNER TO POSTGRES;

