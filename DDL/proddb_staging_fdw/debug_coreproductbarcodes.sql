CREATE FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_COREPRODUCTBARCODES
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "coreProductId" integer OPTIONS (column_name 'coreProductId'),
        BARCODE varchar(255) OPTIONS (column_name 'barcode'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        LOAD_ID integer OPTIONS (column_name 'load_id')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'staging', table_name 'debug_coreproductbarcodes');

ALTER FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_COREPRODUCTBARCODES
    OWNER TO POSTGRES;

