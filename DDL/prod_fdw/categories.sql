CREATE FOREIGN TABLE PROD_FDW.CATEGORIES
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        NAME varchar(255) OPTIONS (column_name 'name'),
        "categoryId" integer OPTIONS (column_name 'categoryId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        COLOR varchar(255) OPTIONS (column_name 'color') NOT NULL,
        "measurementUnit" varchar(255) OPTIONS (column_name 'measurementUnit'),
        "pricePer" varchar(255) OPTIONS (column_name 'pricePer')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'categories');

ALTER FOREIGN TABLE PROD_FDW.CATEGORIES
    OWNER TO POSTGRES;

