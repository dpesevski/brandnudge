CREATE FOREIGN TABLE PROD_FDW.PROMOTIONS
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "retailerPromotionId" integer OPTIONS (column_name 'retailerPromotionId') NOT NULL,
        "productId" integer OPTIONS (column_name 'productId') NOT NULL,
        DESCRIPTION text OPTIONS (column_name 'description') NOT NULL,
        "startDate" varchar(255) OPTIONS (column_name 'startDate'),
        "endDate" varchar(255) OPTIONS (column_name 'endDate'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        "promoId" text OPTIONS (column_name 'promoId'),
        LOAD_ID integer OPTIONS (column_name 'load_id')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'promotions');

ALTER FOREIGN TABLE PROD_FDW.PROMOTIONS
    OWNER TO POSTGRES;

