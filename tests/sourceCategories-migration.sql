ALTER TABLE "productsData"
    DROP COLUMN "sourceCategoryId";


/*
FK to "sourceCategories"
+---------------------------+
|TABLE_NAME                 |
+---------------------------+
|productsData               |
|companySourceCategories    |
|coreProductSourceCategories|
+---------------------------+
*/

DROP TABLE "companySourceCategories";
DROP TABLE "coreProductSourceCategories";
DROP TABLE "userSourceCategories";
DROP TABLE "sourceCategories";

/*  only once, in current staging */

ALTER TABLE staging.debug_productsdata
    DROP COLUMN "sourceCategoryId";

ALTER TABLE staging.load
    DROP COLUMN dd_sourceCategoryType;

DROP TABLE IF EXISTS staging.debug_coreproductsourcecategories;
DROP TABLE IF EXISTS staging.debug_sourcecategories;
