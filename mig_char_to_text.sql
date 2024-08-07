/*
ALTER TABLE retailers
    ALTER COLUMN "createdAt" SET DEFAULT NOW();
ALTER TABLE retailers
    ALTER COLUMN "updatedAt" SET DEFAULT NOW();
*/

/*  deployed in prod*/
ALTER TABLE staging.debug_promotions
    ALTER COLUMN "promoId" TYPE text USING "promoId"::text;

ALTER TABLE products
    ALTER COLUMN "productTitle" TYPE text USING "productTitle"::text;
ALTER TABLE products
    ALTER COLUMN "productTitleDetail" TYPE text USING "productTitleDetail"::text;
ALTER TABLE "errorLogs"
    ALTER COLUMN "message" TYPE text USING "message"::text;
ALTER TABLE "coreProductCountryData"
    ALTER COLUMN "title" TYPE text USING "title"::text;
ALTER TABLE "coreProductCountryData"
    ALTER COLUMN "image" TYPE text USING "image"::text;
ALTER TABLE "coreProducts"
    ALTER COLUMN "title" TYPE text USING "title"::text;
ALTER TABLE "coreProducts"
    ALTER COLUMN "image" TYPE text USING "image"::text;

/*
ALTER TABLE staging.debug_promotions
    ALTER COLUMN "promoId" TYPE text USING "promoId"::text;


ALTER TABLE staging.debug_products
    ALTER COLUMN "productTitle" TYPE text USING "productTitle"::text;
ALTER TABLE staging.debug_products
    ALTER COLUMN "productTitleDetail" TYPE text USING "productTitleDetail"::text;

ALTER TABLE staging.debug_coreProductCountryData
    ALTER COLUMN "title" TYPE text USING "title"::text;
ALTER TABLE staging.debug_coreProductCountryData
    ALTER COLUMN "image" TYPE text USING "image"::text;
ALTER TABLE staging.debug_coreProducts
    ALTER COLUMN "title" TYPE text USING "title"::text;
ALTER TABLE staging.debug_coreProducts
    ALTER COLUMN "image" TYPE text USING "image"::text;

ALTER TABLE staging.debug_coreProductBarcodes ALTER COLUMN "barcode" TYPE text USING "barcode"::text;
ALTER TABLE staging.debug_coreProducts
    ALTER COLUMN "ean" TYPE text USING "ean"::text;
ALTER TABLE staging.debug_coreRetailers
    ALTER COLUMN "productId" TYPE text USING "productId"::text;
*/


/*  latest  updates - to be run in prod*/
ALTER TABLE "coreProductBarcodes"
    ALTER COLUMN "barcode" TYPE text USING "barcode"::text;
ALTER TABLE "coreProducts"
    ALTER COLUMN "ean" TYPE text USING "ean"::text;
ALTER TABLE "coreRetailers"
    ALTER COLUMN "productId" TYPE text USING "productId"::text;
ALTER TABLE "products"
    ALTER COLUMN "sourceType" TYPE text USING "sourceType"::text;
ALTER TABLE "products"
    ALTER COLUMN "ean" TYPE text USING "ean"::text;
ALTER TABLE "products"
    ALTER COLUMN "sourceId" TYPE text USING "sourceId"::text;
ALTER TABLE "products"
    ALTER COLUMN "productBrand" TYPE text USING "productBrand"::text;
ALTER TABLE "products"
    ALTER COLUMN "eposId" TYPE text USING "eposId"::text;
ALTER TABLE "productsData"
    ALTER COLUMN "category" TYPE text USING "category"::text;
ALTER TABLE "productsData"
    ALTER COLUMN "categoryType" TYPE text USING "categoryType"::text;
ALTER TABLE "productsData"
    ALTER COLUMN "parentCategory" TYPE text USING "parentCategory"::text;
ALTER TABLE "retailers"
    ALTER COLUMN "name" TYPE text USING "name"::text;
ALTER TABLE "sourceCategories"
    ALTER COLUMN "name" TYPE text USING "name"::text;

ALTER TABLE "productsData"
    ALTER COLUMN "screenshot" TYPE text USING "screenshot"::text;
ALTER TABLE "productStatuses"
    ALTER COLUMN "screenshot" TYPE text USING "screenshot"::text;

/*
ALTER TABLE  staging.debug_coreProductBarcodes ALTER COLUMN "barcode" TYPE text USING "barcode"::text;
ALTER TABLE  staging.debug_coreProducts ALTER COLUMN "ean" TYPE text USING "ean"::text;
ALTER TABLE  staging.debug_coreRetailers ALTER COLUMN "productId" TYPE text USING "productId"::text;
ALTER TABLE  staging.debug_products ALTER COLUMN "sourceType" TYPE text USING "sourceType"::text;
ALTER TABLE  staging.debug_products ALTER COLUMN "ean" TYPE text USING "ean"::text;
ALTER TABLE  staging.debug_products ALTER COLUMN "sourceId" TYPE text USING "sourceId"::text;
ALTER TABLE  staging.debug_products ALTER COLUMN "productBrand" TYPE text USING "productBrand"::text;
ALTER TABLE  staging.debug_products ALTER COLUMN "eposId" TYPE text USING "eposId"::text;
ALTER TABLE  staging.debug_productsData ALTER COLUMN "category" TYPE text USING "category"::text;
ALTER TABLE  staging.debug_productsData ALTER COLUMN "categoryType" TYPE text USING "categoryType"::text;
ALTER TABLE  staging.debug_productsData ALTER COLUMN "parentCategory" TYPE text USING "parentCategory"::text;
ALTER TABLE  staging.debug_retailers ALTER COLUMN "name" TYPE text USING "name"::text;
ALTER TABLE  staging.debug_sourceCategories ALTER COLUMN "name" TYPE text USING "name"::text;

ALTER TABLE  staging.debug_productsData ALTER COLUMN "screenshot" TYPE text USING "screenshot"::text;
ALTER TABLE  staging.debug_productStatuses ALTER COLUMN "screenshot" TYPE text USING "screenshot"::text;
*/