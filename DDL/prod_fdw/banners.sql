CREATE FOREIGN TABLE PROD_FDW.BANNERS
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        IMAGE text OPTIONS (column_name 'image'),
        CATEGORY varchar(255) OPTIONS (column_name 'category'),
        "retailerId" integer OPTIONS (column_name 'retailerId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        "categoryType" varchar(255) OPTIONS (column_name 'categoryType'),
        TITLE varchar(255) OPTIONS (column_name 'title'),
        SCREENSHOT text OPTIONS (column_name 'screenshot'),
        "bannerId" text OPTIONS (column_name 'bannerId') NOT NULL,
        "startDate" timestamp with time zone OPTIONS (column_name 'startDate') NOT NULL,
        "endDate" timestamp with time zone OPTIONS (column_name 'endDate') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'banners');

ALTER FOREIGN TABLE PROD_FDW.BANNERS
    OWNER TO POSTGRES;

