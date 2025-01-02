CREATE FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_TMP_PRODUCT_PP
    (
        LOAD_ID integer OPTIONS (column_name 'load_id'),
        ID integer OPTIONS (column_name 'id'),
        "sourceType" varchar(255) OPTIONS (column_name 'sourceType'),
        EAN text OPTIONS (column_name 'ean'),
        "promotionDescription" text OPTIONS (column_name 'promotionDescription'),
        FEATURES text OPTIONS (column_name 'features'),
        DATE date OPTIONS (column_name 'date'),
        "sourceId" text OPTIONS (column_name 'sourceId'),
        "productBrand" text OPTIONS (column_name 'productBrand'),
        "productTitle" text OPTIONS (column_name 'productTitle'),
        "productImage" text OPTIONS (column_name 'productImage'),
        "newCoreImage" text OPTIONS (column_name 'newCoreImage'),
        "secondaryImages" boolean OPTIONS (column_name 'secondaryImages'),
        "productDescription" text OPTIONS (column_name 'productDescription'),
        "productInfo" text OPTIONS (column_name 'productInfo'),
        "promotedPrice" double precision OPTIONS (column_name 'promotedPrice'),
        "productInStock" boolean OPTIONS (column_name 'productInStock'),
        "productInListing" boolean OPTIONS (column_name 'productInListing'),
        "reviewsCount" integer OPTIONS (column_name 'reviewsCount'),
        "reviewsStars" double precision OPTIONS (column_name 'reviewsStars'),
        "eposId" text OPTIONS (column_name 'eposId'),
        MULTIBUY boolean OPTIONS (column_name 'multibuy'),
        "coreProductId" integer OPTIONS (column_name 'coreProductId'),
        "retailerId" integer OPTIONS (column_name 'retailerId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt'),
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt'),
        "imageId" text OPTIONS (column_name 'imageId'),
        SIZE text OPTIONS (column_name 'size'),
        "pricePerWeight" text OPTIONS (column_name 'pricePerWeight'),
        HREF text OPTIONS (column_name 'href'),
        NUTRITIONAL text OPTIONS (column_name 'nutritional'),
        "basePrice" double precision OPTIONS (column_name 'basePrice'),
        "shelfPrice" double precision OPTIONS (column_name 'shelfPrice'),
        "productTitleDetail" text OPTIONS (column_name 'productTitleDetail'),
        "sizeUnit" text OPTIONS (column_name 'sizeUnit'),
        "dateId" integer OPTIONS (column_name 'dateId'),
        "countryCode" text OPTIONS (column_name 'countryCode'),
        CURRENCY text OPTIONS (column_name 'currency'),
        "cardPrice" double precision OPTIONS (column_name 'cardPrice'),
        "onPromo" boolean OPTIONS (column_name 'onPromo'),
        BUNDLED boolean OPTIONS (column_name 'bundled'),
        "originalPrice" double precision OPTIONS (column_name 'originalPrice'),
        "productPrice" double precision OPTIONS (column_name 'productPrice'),
        STATUS text OPTIONS (column_name 'status'),
        "productOptions" boolean OPTIONS (column_name 'productOptions'),
        SHOP text OPTIONS (column_name 'shop'),
        "amazonShop" text OPTIONS (column_name 'amazonShop'),
        CHOICE text OPTIONS (column_name 'choice'),
        "amazonChoice" text OPTIONS (column_name 'amazonChoice'),
        "lowStock" boolean OPTIONS (column_name 'lowStock'),
        "sellParty" text OPTIONS (column_name 'sellParty'),
        "amazonSellParty" text OPTIONS (column_name 'amazonSellParty'),
        SELL text OPTIONS (column_name 'sell'),
        "fulfilParty" text OPTIONS (column_name 'fulfilParty'),
        "amazonFulfilParty" text OPTIONS (column_name 'amazonFulfilParty'),
        "amazonSell" text OPTIONS (column_name 'amazonSell'),
        MARKETPLACE boolean OPTIONS (column_name 'marketplace'),
        "marketplaceData" JSON OPTIONS (column_name 'marketplaceData'),
        "priceMatchDescription" text OPTIONS (column_name 'priceMatchDescription'),
        "priceMatch" boolean OPTIONS (column_name 'priceMatch'),
        "priceLock" boolean OPTIONS (column_name 'priceLock'),
        "isNpd" boolean OPTIONS (column_name 'isNpd'),
        "eanIssues" boolean OPTIONS (column_name 'eanIssues'),
        SCREENSHOT text OPTIONS (column_name 'screenshot'),
        "brandId" integer OPTIONS (column_name 'brandId'),
        "EANs" text[] OPTIONS (column_name 'EANs'),
        PROMOTIONS STAGING.T_PROMOTION_MB[] OPTIONS (column_name 'promotions')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'staging', table_name 'debug_tmp_product_pp');

ALTER FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_TMP_PRODUCT_PP
    OWNER TO POSTGRES;

