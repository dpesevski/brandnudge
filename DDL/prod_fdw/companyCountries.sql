CREATE FOREIGN TABLE PROD_FDW."companyCountries"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "companyId" integer OPTIONS (column_name 'companyId'),
        "countryId" integer OPTIONS (column_name 'countryId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'companyCountries');

ALTER FOREIGN TABLE PROD_FDW."companyCountries"
    OWNER TO POSTGRES;

