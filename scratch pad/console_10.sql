SELECT "productsData".category,
       "productsData"."categoryType",
       "product"."retailerId",
       "product"."dateId",
       MAX("productRank")  AS "productRankCount",
       MAX("featuredRank") AS "featuredRankCount"
FROM "products" AS "product"
         INNER JOIN "productsData" AS "productsData" ON "product"."id" = "productsData"."productId" AND
                                                        ("productsData"."featuredRank" <= 20 OR "productsData"."productRank" <= 20)
GROUP BY "productsData".category, "productsData"."categoryType", "product"."retailerId", "dateId";

--2023-12-06 12:00:00.000000 +00:00

CREATE TABLE staging.products AS
SELECT *
FROM products
WHERE DATE >= '2023-12-06';

CREATE TABLE staging."productsData" AS
WITH products AS (SELECT id AS "productId" FROM staging.products)
SELECT *
FROM "productsData"
         INNER JOIN products USING ("productId");

CREATE TABLE staging."productStatuses" AS
WITH products AS (SELECT id AS "productId" FROM staging.products)
SELECT *
FROM "productStatuses"
         INNER JOIN products USING ("productId");

CREATE TABLE staging."promotions" AS
WITH products AS (SELECT id AS "productId" FROM staging.products)
SELECT *
FROM "promotions"
         INNER JOIN products USING ("productId");

CREATE TABLE staging."aggregatedProducts" AS
WITH products AS (SELECT id AS "productId" FROM staging.products)
SELECT *
FROM "aggregatedProducts"
         INNER JOIN products USING ("productId");

CREATE TABLE staging."latest_productsData" AS
WITH products AS (SELECT id AS "productId" FROM staging.products)
SELECT *
FROM "productsData"
         INNER JOIN products USING ("productId");

SELECT COUNT(*)
FROM staging."productsData";
SELECT COUNT(*)
FROM staging."products";

--CREATE TABLE staging.agg_category_rank_by_date AS
SELECT "productsData".category,
       "productsData"."categoryType",
       "product"."retailerId",
       "product".date,
       MAX("productRank")  AS "productRankCount",
       MAX("featuredRank") AS "featuredRankCount"
FROM staging.products AS "product"
         INNER JOIN staging."productsData" AS "productsData" ON "product"."id" = "productsData"."productId"
GROUP BY "productsData".category, "productsData"."categoryType", "product"."retailerId", date;

DROP TABLE tests.staging_products;
CREATE TABLE tests.staging_products AS
WITH status AS (WITH status AS (SELECT "productId"                                                            AS id,
                                       status = 'de-listed'                                                   AS is_delisted,
                                       ROW_NUMBER() OVER (PARTITION BY "productId" ORDER BY "updatedAt" DESC) AS row_num
                                FROM staging."productStatuses")
                SELECT id,
                       is_delisted
                FROM status
                WHERE row_num = 1),
     ranking AS (SELECT "productId"             AS id,
                        ARRAY_AGG((
                                   date,
                                   category,
                                   "categoryType",
                                   "parentCategory",
                                   "productRank",
                                   "sourceCategoryId",
                                   featured,
                                   "featuredRank",
                                   "taxonomyId"
                            )::product_ranking) AS ranking
                 FROM staging."productsData"
                          INNER JOIN (SELECT id AS "productId", date FROM staging.products) AS products
                                     USING ("productId")
                 GROUP BY "productId")
SELECT *
FROM staging.products
         LEFT OUTER JOIN status USING (id)
         LEFT OUTER JOIN ranking USING (id);


/*  maintain a single record for promotions, based on promoId   */
--  new promotions (to be inserted)
SELECT *
FROM staging.promotions
WHERE "startDate"::date = '2023-12-06';

--  ongoing promotions - to be updated (endDate?)
SELECT *
FROM staging.promotions
WHERE "startDate"::date = '2023-12-06';


-- at the moment only 2% of the records are ongoing promotions.
-- should keep a separate table for ongoing/active records and expired/in-active ones


SELECT COUNT(CASE WHEN is_expired THEN 1 END)         AS expired_promotions_count,
       COUNT(CASE WHEN NOT is_expired THEN 1 END)     AS ongoing_promotions_count,
       COUNT(CASE WHEN is_expired IS NULL THEN 1 END) AS unknow_status_count,
       COUNT(*)
FROM promotions
         CROSS JOIN LATERAL (SELECT CASE
                                        WHEN "endDate" IS NULL THEN NULL
                                        WHEN "endDate" = '' THEN NULL
                                        ELSE "endDate"::date < '2023-12-06' END AS is_expired) lat_status;


select count(*) from agg_category_rank_by_date