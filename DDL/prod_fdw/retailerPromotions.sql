CREATE FOREIGN TABLE PROD_FDW."retailerPromotions"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "retailerId" integer OPTIONS (column_name 'retailerId') NOT NULL,
        "promotionMechanicId" integer OPTIONS (column_name 'promotionMechanicId') NOT NULL,
        REGEXP text OPTIONS (column_name 'regexp') NOT NULL,
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'retailerPromotions');

ALTER FOREIGN TABLE PROD_FDW."retailerPromotions"
    OWNER TO POSTGRES;

