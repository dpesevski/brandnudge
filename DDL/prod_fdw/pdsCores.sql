CREATE FOREIGN TABLE PROD_FDW."pdsCores"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        SKU varchar(255) OPTIONS (column_name 'sku'),
        RETAILER varchar(255) OPTIONS (column_name 'retailer'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'pdsCores');

ALTER FOREIGN TABLE PROD_FDW."pdsCores"
    OWNER TO POSTGRES;

