CREATE FOREIGN TABLE PROD_FDW."scrapperLinks"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        URL varchar(1024) OPTIONS (column_name 'url'),
        CATEGORY varchar(255) OPTIONS (column_name 'category'),
        "categoryType" varchar(255) OPTIONS (column_name 'categoryType'),
        RETAILER varchar(255) OPTIONS (column_name 'retailer'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'scrapperLinks');

ALTER FOREIGN TABLE PROD_FDW."scrapperLinks"
    OWNER TO POSTGRES;

