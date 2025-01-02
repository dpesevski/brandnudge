CREATE FOREIGN TABLE PROD_FDW."productGroupManufacturers"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "productGroupId" integer OPTIONS (column_name 'productGroupId'),
        "manufacturerId" integer OPTIONS (column_name 'manufacturerId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'productGroupManufacturers');

ALTER FOREIGN TABLE PROD_FDW."productGroupManufacturers"
    OWNER TO POSTGRES;

