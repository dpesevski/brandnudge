CREATE FOREIGN TABLE PROD_FDW.TAXONOMIES
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        LEVEL integer OPTIONS (column_name 'level'),
        CATEGORY varchar(255) OPTIONS (column_name 'category'),
        RETAILER varchar(255) OPTIONS (column_name 'retailer'),
        "taxonomyId" integer OPTIONS (column_name 'taxonomyId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        DATE timestamp with time zone OPTIONS (column_name 'date'),
        POSITION integer OPTIONS (column_name 'position'),
        "productsCount" integer OPTIONS (column_name 'productsCount')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'taxonomies');

ALTER FOREIGN TABLE PROD_FDW.TAXONOMIES
    OWNER TO POSTGRES;

