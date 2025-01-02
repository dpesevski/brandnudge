CREATE FOREIGN TABLE PROD_FDW."coreProductTaggings"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "coreProductId" integer OPTIONS (column_name 'coreProductId'),
        "coreTaggingId" integer OPTIONS (column_name 'coreTaggingId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'coreProductTaggings');

ALTER FOREIGN TABLE PROD_FDW."coreProductTaggings"
    OWNER TO POSTGRES;

