CREATE FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_AGGREGATEDPRODUCTS
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "titleMatch" varchar(255) OPTIONS (column_name 'titleMatch'),
        "productId" integer OPTIONS (column_name 'productId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        FEATURES varchar(255) OPTIONS (column_name 'features'),
        SPECIFICATION varchar(255) OPTIONS (column_name 'specification'),
        SIZE varchar(255) OPTIONS (column_name 'size'),
        DESCRIPTION varchar(255) OPTIONS (column_name 'description'),
        INGREDIENTS varchar(255) OPTIONS (column_name 'ingredients'),
        "imageMatch" varchar(255) OPTIONS (column_name 'imageMatch'),
        LOAD_ID integer OPTIONS (column_name 'load_id')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'staging', table_name 'debug_aggregatedproducts');

ALTER FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_AGGREGATEDPRODUCTS
    OWNER TO POSTGRES;

