CREATE FOREIGN TABLE PROD_FDW.BRANDS
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        NAME varchar(255) OPTIONS (column_name 'name'),
        "manufacturerId" integer OPTIONS (column_name 'manufacturerId'),
        "checkList" varchar(1024) OPTIONS (column_name 'checkList'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        "brandId" integer OPTIONS (column_name 'brandId'),
        COLOR varchar(255) OPTIONS (column_name 'color') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'brands');

ALTER FOREIGN TABLE PROD_FDW.BRANDS
    OWNER TO POSTGRES;

