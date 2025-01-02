CREATE FOREIGN TABLE PROD_FDW.TESCO_CORRECTED_PRICES
    (
        ID integer OPTIONS (column_name 'id'),
        "sourceId" varchar(255) OPTIONS (column_name 'sourceId'),
        DATE timestamp with time zone OPTIONS (column_name 'date'),
        "promotionDescription" text OPTIONS (column_name 'promotionDescription'),
        EAN varchar(255) OPTIONS (column_name 'ean'),
        "retailerId" integer OPTIONS (column_name 'retailerId'),
        "sourceType" varchar(255) OPTIONS (column_name 'sourceType'),
        "coreProductId" integer OPTIONS (column_name 'coreProductId'),
        "basePrice" varchar(255) OPTIONS (column_name 'basePrice'),
        "current_shelfPrice" varchar(255) OPTIONS (column_name 'current_shelfPrice'),
        "current_promotedPrice" varchar(255) OPTIONS (column_name 'current_promotedPrice'),
        "correct_shelfPrice" varchar(255) OPTIONS (column_name 'correct_shelfPrice'),
        "correct_promotedPrice" varchar(255) OPTIONS (column_name 'correct_promotedPrice'),
        HREF text OPTIONS (column_name 'href')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'tesco_corrected_prices');

ALTER FOREIGN TABLE PROD_FDW.TESCO_CORRECTED_PRICES
    OWNER TO POSTGRES;

