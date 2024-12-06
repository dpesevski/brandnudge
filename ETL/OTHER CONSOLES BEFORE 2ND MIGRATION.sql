/*  1. UPDATE "coreRetailerSources" */
UPDATE "coreRetailerSources"
SET "coreRetailerId"=$1,
    "updatedAt"=$2
WHERE "id" = $3;

SELECT "updatedAt"::date, COUNT(*)
FROM "coreRetailerSources"
WHERE "updatedAt" > "createdAt"
  AND "updatedAt" >= '2024-11-01'
GROUP BY 1

/*  2. RANKING  */
DROP TABLE IF EXISTS staging."productsData";
CREATE TABLE staging."productsData" AS
WITH "productsData" AS (SELECT id,
                               "productId",
                               category,
                               "categoryType",
                               "parentCategory",
                               "productRank",
                               "pageNumber",
                               screenshot,
                               featured,
                               "featuredRank",
                               "taxonomyId",
                               load_id,
                               "retailerId",
                               "dateId",
                               "coreProductId"
                        FROM (SELECT id AS "productId", "retailerId", "dateId", "coreProductId"
                              FROM products
                              WHERE "dateId" = 29056) AS products --2024-11-01
                                 INNER JOIN "productsData" USING ("productId"))
SELECT *
FROM "productsData";

SELECT *
FROM staging."productsData";

WITH products_count AS (SELECT category,
                               "categoryType",
                               "retailerId",
                               "dateId",
                               LEAST(MAX("productRank"), 20)  AS "productRankCount",
                               LEAST(MAX("featuredRank"), 20) AS "featuredRankCount"
                        FROM staging."productsData"
                        GROUP BY CATEGORY, "categoryType", "retailerId", "dateId")
SELECT category,
       "categoryType",
       "retailerId",
       "dateId",
       "manufacturerId",
       COUNT(*) FILTER ( WHERE "productRank" <= 20 )  AS "mnf_productRankCount",
       COUNT(*) FILTER ( WHERE "featuredRank" <= 20 ) AS "mnf_featuredRankCount"
FROM staging."productsData"
         INNER JOIN products_count USING (category,
                                          "categoryType",
                                          "retailerId",
                                          "dateId")
         INNER JOIN (SELECT id AS "coreProductId", "manufacturerId"
                     FROM "coreProducts"
                              INNER JOIN (SELECT brands.id AS "brandId", "manufacturerId" FROM brands) AS brands
                                         USING ("brandId")) AS "coreProducts" USING ("coreProductId")
WHERE category = 'Long Life Juice'
  AND "categoryType" = 'aisle'
  AND "retailerId" = 1
GROUP BY category,
         "categoryType",
         "retailerId",
         "dateId",
         "manufacturerId";



SELECT *
FROM manufacturers

SELECT *
FROM staging."productsData"
WHERE category = 'Long Life Juice'
  AND "categoryType" = 'aisle'
  AND ("featuredRank" <= 20 OR "productRank" <= 20)


WITH RANKING AS (SELECT category,
                        "categoryType",
                        "retailerId",
                        "dateId",
                        LEAST(MAX("productRank"), 20)  AS "productRankCount",
                        LEAST(MAX("featuredRank"), 20) AS "featuredRankCount"
                 FROM (SELECT id AS "productId", "retailerId", "dateId"
                       FROM products
                       WHERE "dateId" = 29056) AS products --2024-11-01
                          INNER JOIN "productsData" USING ("productId")
                 GROUP BY category, "categoryType", "retailerId", "dateId")
SELECT category,
       "categoryType",
       "retailerId",
       "dateId",
       "productRankCount",
       "featuredRankCount"
FROM RANKING
WHERE category = 'Long Life Juice'
  AND "categoryType" = 'aisle'

/*  3. LONG RUNNING QUERY   */
WITH cte AS (SELECT DATE_TRUNC('day', DATES.date) AS "Date",
                    INITCAP(PROD."sourceType")    AS "Retailer",
                    "sourceId",
                    CAT.name                      AS "Category",
                    BRAND.name                    AS "Brand",
                    COREPROD.ean                  AS "EAN",
                    PROD."productTitle"           AS "Retailer Product Title",
                    COREPROD."title"              AS "Brand Nudge Product Title",
                    MANUFACTURER.name             AS "Manufacturer",
                    PROD."productInfo"            AS "Ingredients",
                    PROD."size"                   AS "Retailer Size",
                    COREPROD."size"               AS "Brand Nudge Size",
                    PROD."promotions"             AS "Promotions",
                    PROMO_MECHANIC."name"         AS "Promotion Mechanic",
                    PROMO."description"           AS "Promotion Description",
                    PROD."basePrice"              AS "Base Price",
                    CASE
                        WHEN PROD."retailerId" = '1'
                            AND PROMO_MECHANIC."name" = 'Price Cut'
                            THEN PROD."promotedPrice"
                        ELSE PROD."shelfPrice"
                        END                       AS "Shelf Price",
                    PROD."promotedPrice"          AS "Promoted Price",
                    PROD."productImage"           AS "Image URL",
                    PROD."href"                   AS "Product URL",
                    (SELECT DATE_TRUNC('day', PROD1.date)
                     FROM products AS PROD1
                              INNER JOIN dates AS DATES1 ON PROD1."dateId" = DATES1.id
                     WHERE PROD1."sourceId" = PROD."sourceId"
                       AND PROD1."sourceType" = PROD."sourceType"
                     ORDER BY PROD1."createdAt" ASC
                     LIMIT 1)                     AS "First Seen"
             FROM products AS PROD
                      INNER JOIN "dates" AS DATES ON PROD."dateId" = DATES.id
                      INNER JOIN "coreProducts" AS COREPROD ON PROD."coreProductId" = COREPROD.id
                      INNER JOIN "categories" AS CAT ON COREPROD."categoryId" = CAT.id
                      INNER JOIN "brands" AS BRAND ON COREPROD."brandId" = BRAND.id
                      INNER JOIN "manufacturers" AS MANUFACTURER ON BRAND."manufacturerId" = MANUFACTURER.id
                      LEFT JOIN "promotions" AS PROMO ON PROD."id" = PROMO."productId"
                      LEFT JOIN "retailerPromotions" AS RETAILER_PROMO
                                ON PROMO."retailerPromotionId" = RETAILER_PROMO.id
                      LEFT JOIN "promotionMechanics" AS PROMO_MECHANIC
                                ON RETAILER_PROMO."promotionMechanicId" = PROMO_MECHANIC.id

             WHERE DATE_TRUNC('day', DATES.date) >= '2024-11-23'
               AND PROD."retailerId" IN (SELECT "retailerId"
                                         FROM "companyRetailers"
                                         WHERE "companyId" = '965')
               AND COREPROD."categoryId" IN (SELECT "categoryId"
                                             FROM "companyCoreCategories"
                                             WHERE "companyId" = '965')
               AND PROD."shelfPrice" <> '0'
             ORDER BY DATES.date, PROD."sourceType", CAT.name)

SELECT "EAN",
       "Retailer",
       "Category",
       "Retailer Product Title",
       "Brand Nudge Product Title",
       "Brand",
       "First Seen",
       "Base Price",
       "Shelf Price"
FROM cte
WHERE "First Seen" >= '2024-11-23'
  AND "Date" = "First Seen"
ORDER BY "EAN"