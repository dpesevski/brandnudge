CREATE SCHEMA IF NOT EXISTS test;

DROP TABLE IF EXISTS test.tprd_products;
CREATE TABLE IF NOT EXISTS test.tprd_products AS
SELECT *
FROM prod_fdw.products
         INNER JOIN (SELECT id AS "dateId", date AS dates_date FROM prod_fdw.dates) AS dates USING ("dateId")
WHERE "dateId" > 24436;

DROP TABLE IF EXISTS test.tstg_products;
CREATE TABLE IF NOT EXISTS test.tstg_products AS
SELECT *
FROM products
         INNER JOIN (SELECT id AS "dateId", date AS dates_date FROM dates) AS dates USING ("dateId")
WHERE "dateId" > 24436;

CREATE INDEX IF NOT EXISTS tprd_products_retailerId_date_sourceId_index
    ON test.tprd_products ("retailerId", dates_date, "sourceId");

CREATE INDEX IF NOT EXISTS tstg_products_retailerId_date_sourceId_index
    ON test.tstg_products ("retailerId", dates_date, "sourceId");

SELECT *
FROM dates
WHERE id > 24436
ORDER BY "createdAt" DESC NULLS LAST;

SELECT *
FROM prod_fdw.dates
WHERE id > 24436
ORDER BY "createdAt" DESC NULLS LAST;

SELECT COUNT(*)
FROM products
WHERE "dateId" > 24436;

SELECT COUNT(*)
FROM prod_fdw.products
WHERE "dateId" > 24436;

WITH prod AS (SELECT DISTINCT dates_date, "sourceId", "retailerId"
              FROM test.tprd_products),
     staging AS (SELECT DISTINCT dates_date, "sourceId", "retailerId"
                 FROM test.tstg_products),
     prod_cnt AS (SELECT "retailerId", COUNT(prod.*) AS prod_prd_count, COUNT(staging.*) AS stg_prd_count
                  FROM prod
                           FULL OUTER JOIN staging USING ("retailerId", dates_date, "sourceId")
                  GROUP BY "retailerId")
SELECT "retailerId",
       is_pp,
       prod_prd_count,
       stg_prd_count,
       CASE WHEN is_pp THEN prod_prd_count - stg_prd_count END AS prd_count_diff
FROM prod_cnt
         LEFT OUTER JOIN test.retailer USING ("retailerId")
ORDER BY "retailerId";

SELECT *
FROM test.tstg_products AS staging
         LEFT OUTER JOIN test.tprd_products AS prod
                         USING ("retailerId", dates_date, "sourceId")
WHERE prod.id IS NULL;

SELECT COUNT(*)
FROM test.tstg_products AS staging
         LEFT OUTER JOIN test.tprd_products AS prod
                         USING ("retailerId", dates_date, "sourceId")
WHERE staging."sourceType" != prod."sourceType"
   -- OR staging.ean != prod.ean
   OR staging.promotions != prod.promotions
   OR staging."promotionDescription" != prod."promotionDescription"
   OR staging.features != prod.features
   OR staging."productBrand" != prod."productBrand"
   OR staging."productTitle" != prod."productTitle"
   OR staging."productImage" != prod."productImage"
   OR staging."secondaryImages" != prod."secondaryImages"
   OR staging."productDescription" != prod."productDescription"
   OR staging."productInfo" != prod."productInfo"
   -- OR staging."promotedPrice" != prod."promotedPrice"
   OR staging."productInStock" != prod."productInStock"
   OR staging."productInListing" != prod."productInListing"
   OR staging."reviewsCount" != prod."reviewsCount"
   OR staging."reviewsStars" != prod."reviewsStars"
   OR staging."eposId" != prod."eposId"
   --OR staging.multibuy != prod.multibuy
   --OR staging."coreProductId" != prod."coreProductId"
   OR staging."imageId" != prod."imageId"
   OR staging.size != prod.size
   OR staging."pricePerWeight" != prod."pricePerWeight"
   OR staging.href != prod.href
   OR staging.nutritional != prod.nutritional
   --OR staging."basePrice" != prod."basePrice"
   --OR staging."shelfPrice" != prod."shelfPrice"
   OR staging."productTitleDetail" != prod."productTitleDetail"
   OR staging."sizeUnit" != prod."sizeUnit"
   OR staging.marketplace != prod.marketplace
   OR staging."marketplaceData"::text != prod."marketplaceData"::text
   OR staging."priceMatchDescription" != prod."priceMatchDescription"
   OR staging."priceMatched" != prod."priceMatched";



SELECT staging."promotedPrice" AS stag_promotedPrice,
       prod."promotedPrice"    AS prod_promotedPrice,
       staging."basePrice"     AS stag_basePrice,
       prod."basePrice"        AS prod_basePrice,
       staging."shelfPrice"    AS stag_shelfPrice,
       prod."shelfPrice"       AS prod_shelfPrice,
       prod.*
FROM test.tstg_products AS staging
         LEFT OUTER JOIN test.tprd_products AS prod
                         USING ("retailerId", dates_date, "sourceId")
WHERE
   --OR staging.multibuy != prod.multibuy
--OR staging."coreProductId" != prod."coreProductId"
    staging."promotedPrice"::numeric != prod."promotedPrice"::numeric
   OR staging."basePrice"::numeric != REPLACE(prod."basePrice", ',', '')::numeric
   OR staging."shelfPrice"::numeric != prod."shelfPrice"::numeric
