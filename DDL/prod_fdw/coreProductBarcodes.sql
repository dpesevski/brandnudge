CREATE FOREIGN TABLE PROD_FDW."coreProductBarcodes"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "coreProductId" integer OPTIONS (column_name 'coreProductId'),
        BARCODE varchar(255) OPTIONS (column_name 'barcode'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        LOAD_ID integer OPTIONS (column_name 'load_id')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'coreProductBarcodes');

ALTER FOREIGN TABLE PROD_FDW."coreProductBarcodes"
    OWNER TO POSTGRES;

