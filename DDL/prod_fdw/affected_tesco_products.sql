CREATE FOREIGN TABLE PROD_FDW.AFFECTED_TESCO_PRODUCTS
    (
        ID integer OPTIONS (column_name 'id'),
        "sourceId" varchar(255) OPTIONS (column_name 'sourceId'),
        "promotionDescription" text OPTIONS (column_name 'promotionDescription'),
        EAN varchar(255) OPTIONS (column_name 'ean'),
        DATE timestamp with time zone OPTIONS (column_name 'date'),
        "retailerId" integer OPTIONS (column_name 'retailerId'),
        "sourceType" varchar(255) OPTIONS (column_name 'sourceType'),
        "coreProductId" integer OPTIONS (column_name 'coreProductId'),
        "basePrice" varchar(255) OPTIONS (column_name 'basePrice'),
        "shelfPrice" varchar(255) OPTIONS (column_name 'shelfPrice'),
        "promotedPrice" varchar(255) OPTIONS (column_name 'promotedPrice'),
        HREF text OPTIONS (column_name 'href')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'affected_tesco_products');

ALTER FOREIGN TABLE PROD_FDW.AFFECTED_TESCO_PRODUCTS
    OWNER TO POSTGRES;

