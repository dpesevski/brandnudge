CREATE FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_PRODUCTS
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "sourceType" varchar(255) OPTIONS (column_name 'sourceType'),
        EAN varchar(255) OPTIONS (column_name 'ean'),
        PROMOTIONS boolean OPTIONS (column_name 'promotions'),
        "promotionDescription" text OPTIONS (column_name 'promotionDescription'),
        FEATURES text OPTIONS (column_name 'features'),
        DATE timestamp with time zone OPTIONS (column_name 'date') NOT NULL,
        "sourceId" varchar(255) OPTIONS (column_name 'sourceId'),
        "productBrand" varchar(255) OPTIONS (column_name 'productBrand'),
        "productTitle" text OPTIONS (column_name 'productTitle'),
        "productImage" text OPTIONS (column_name 'productImage'),
        "secondaryImages" boolean OPTIONS (column_name 'secondaryImages'),
        "productDescription" text OPTIONS (column_name 'productDescription'),
        "productInfo" text OPTIONS (column_name 'productInfo'),
        "promotedPrice" varchar(255) OPTIONS (column_name 'promotedPrice'),
        "productInStock" boolean OPTIONS (column_name 'productInStock'),
        "productInListing" boolean OPTIONS (column_name 'productInListing'),
        "reviewsCount" varchar(255) OPTIONS (column_name 'reviewsCount'),
        "reviewsStars" varchar(255) OPTIONS (column_name 'reviewsStars'),
        "eposId" varchar(255) OPTIONS (column_name 'eposId'),
        MULTIBUY boolean OPTIONS (column_name 'multibuy'),
        "coreProductId" integer OPTIONS (column_name 'coreProductId') NOT NULL,
        "retailerId" integer OPTIONS (column_name 'retailerId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        "imageId" integer OPTIONS (column_name 'imageId'),
        SIZE varchar(255) OPTIONS (column_name 'size'),
        "pricePerWeight" varchar(255) OPTIONS (column_name 'pricePerWeight'),
        HREF text OPTIONS (column_name 'href'),
        NUTRITIONAL text OPTIONS (column_name 'nutritional'),
        "basePrice" varchar(255) OPTIONS (column_name 'basePrice'),
        "shelfPrice" varchar(255) OPTIONS (column_name 'shelfPrice'),
        "productTitleDetail" text OPTIONS (column_name 'productTitleDetail'),
        "sizeUnit" varchar(255) OPTIONS (column_name 'sizeUnit'),
        "dateId" integer OPTIONS (column_name 'dateId'),
        MARKETPLACE boolean OPTIONS (column_name 'marketplace'),
        "marketplaceData" JSON OPTIONS (column_name 'marketplaceData'),
        "priceMatchDescription" text OPTIONS (column_name 'priceMatchDescription'),
        "priceMatch" boolean OPTIONS (column_name 'priceMatch'),
        "priceLock" boolean OPTIONS (column_name 'priceLock'),
        "isNpd" boolean OPTIONS (column_name 'isNpd'),
        LOAD_ID integer OPTIONS (column_name 'load_id')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'staging', table_name 'debug_products');

ALTER FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_PRODUCTS
    OWNER TO POSTGRES;

