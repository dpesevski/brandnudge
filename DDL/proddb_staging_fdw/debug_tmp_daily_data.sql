CREATE FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_TMP_DAILY_DATA
    (
        LOAD_ID integer OPTIONS (column_name 'load_id'),
        RETAILER RETAILERS OPTIONS (column_name 'retailer'),
        EAN text OPTIONS (column_name 'ean'),
        DATE date OPTIONS (column_name 'date'),
        HREF text OPTIONS (column_name 'href'),
        SIZE text OPTIONS (column_name 'size'),
        "eposId" text OPTIONS (column_name 'eposId'),
        STATUS text OPTIONS (column_name 'status'),
        BUNDLED boolean OPTIONS (column_name 'bundled'),
        CATEGORY text OPTIONS (column_name 'category'),
        FEATURED boolean OPTIONS (column_name 'featured'),
        FEATURES text OPTIONS (column_name 'features'),
        PROMOTIONS STAGING.T_PROMOTION[] OPTIONS (column_name 'promotions'),
        MULTIBUY boolean OPTIONS (column_name 'multibuy'),
        "sizeUnit" text OPTIONS (column_name 'sizeUnit'),
        "sourceId" text OPTIONS (column_name 'sourceId'),
        "inTaxonomy" boolean OPTIONS (column_name 'inTaxonomy'),
        "isFeatured" boolean OPTIONS (column_name 'isFeatured'),
        "pageNumber" text OPTIONS (column_name 'pageNumber'),
        SCREENSHOT text OPTIONS (column_name 'screenshot'),
        "sourceType" text OPTIONS (column_name 'sourceType'),
        "taxonomyId" integer OPTIONS (column_name 'taxonomyId'),
        NUTRITIONAL text OPTIONS (column_name 'nutritional'),
        "productInfo" text OPTIONS (column_name 'productInfo'),
        "productRank" integer OPTIONS (column_name 'productRank'),
        "categoryType" text OPTIONS (column_name 'categoryType'),
        "featuredRank" integer OPTIONS (column_name 'featuredRank'),
        "productBrand" text OPTIONS (column_name 'productBrand'),
        "productImage" text OPTIONS (column_name 'productImage'),
        "newCoreImage" text OPTIONS (column_name 'newCoreImage'),
        "productPrice" double precision OPTIONS (column_name 'productPrice'),
        "productTitle" text OPTIONS (column_name 'productTitle'),
        "reviewsCount" integer OPTIONS (column_name 'reviewsCount'),
        "reviewsStars" double precision OPTIONS (column_name 'reviewsStars'),
        "originalPrice" double precision OPTIONS (column_name 'originalPrice'),
        "pricePerWeight" text OPTIONS (column_name 'pricePerWeight'),
        "productInStock" boolean OPTIONS (column_name 'productInStock'),
        "secondaryImages" boolean OPTIONS (column_name 'secondaryImages'),
        "productDescription" text OPTIONS (column_name 'productDescription'),
        "productTitleDetail" text OPTIONS (column_name 'productTitleDetail'),
        "promotionDescription" text OPTIONS (column_name 'promotionDescription'),
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
        "isNpd" boolean OPTIONS (column_name 'isNpd')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'staging', table_name 'debug_tmp_daily_data');

ALTER FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_TMP_DAILY_DATA
    OWNER TO POSTGRES;

