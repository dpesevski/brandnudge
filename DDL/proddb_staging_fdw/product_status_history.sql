CREATE FOREIGN TABLE PRODDB_STAGING_FDW.PRODUCT_STATUS_HISTORY
    (
        "retailerId" integer OPTIONS (column_name 'retailerId') NOT NULL,
        "coreProductId" integer OPTIONS (column_name 'coreProductId') NOT NULL,
        DATE date OPTIONS (column_name 'date') NOT NULL,
        "productId" integer OPTIONS (column_name 'productId'),
        STATUS text OPTIONS (column_name 'status')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'staging', table_name 'product_status_history');

ALTER FOREIGN TABLE PRODDB_STAGING_FDW.PRODUCT_STATUS_HISTORY
    OWNER TO POSTGRES;

