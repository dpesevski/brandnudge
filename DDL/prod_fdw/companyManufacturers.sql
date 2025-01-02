CREATE FOREIGN TABLE PROD_FDW."companyManufacturers"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "manufacturerId" integer OPTIONS (column_name 'manufacturerId'),
        "companyId" integer OPTIONS (column_name 'companyId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'companyManufacturers');

ALTER FOREIGN TABLE PROD_FDW."companyManufacturers"
    OWNER TO POSTGRES;

