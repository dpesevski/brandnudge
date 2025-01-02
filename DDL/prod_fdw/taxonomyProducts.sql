CREATE FOREIGN TABLE PROD_FDW."taxonomyProducts"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        RETAILER varchar(255) OPTIONS (column_name 'retailer'),
        "sourceId" varchar(255) OPTIONS (column_name 'sourceId'),
        "taxonomyId" integer OPTIONS (column_name 'taxonomyId') NOT NULL,
        DATE timestamp with time zone OPTIONS (column_name 'date') NOT NULL,
        "coreProductId" integer OPTIONS (column_name 'coreProductId') NOT NULL,
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'taxonomyProducts');

ALTER FOREIGN TABLE PROD_FDW."taxonomyProducts"
    OWNER TO POSTGRES;

