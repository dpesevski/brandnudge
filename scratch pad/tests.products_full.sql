CREATE TABLE tests.products_full AS
WITH status AS (WITH status AS (SELECT "coreProductId",
                                       "retailerId",
                                       status = 'de-listed'                                                        AS is_delisted,
                                       ROW_NUMBER()
                                       OVER (PARTITION BY "coreProductId", "retailerId" ORDER BY "updatedAt" DESC) AS row_num
                                FROM "productStatuses"
                                         INNER JOIN (SELECT id AS "productId",
                                                            "coreProductId",
                                                            "retailerId",
                                                            date
                                                     FROM products) AS products USING ("productId"))
                SELECT "coreProductId" AS id,
                       "retailerId",
                       is_delisted
                FROM status
                WHERE row_num = 1),
     ranking AS (WITH products AS (SELECT "coreProductId",
                                          "retailerId",
                                          date,
                                          category,
                                          "categoryType",
                                          "parentCategory",
                                          "productRank",
                                          "sourceCategoryId",
                                          featured,
                                          "featuredRank",
                                          "taxonomyId",

                                          LAG("productRank")
                                          OVER (PARTITION BY "coreProductId", "retailerId", category, "sourceCategoryId" ORDER BY DATE) AS "prev_productRank",
                                          LAG("featuredRank")
                                          OVER (PARTITION BY "coreProductId", "retailerId", category, "sourceCategoryId" ORDER BY DATE) AS "prev_featuredRank"

                                   FROM "productsData"
                                            INNER JOIN (SELECT id AS "productId",
                                                               "coreProductId",
                                                               "retailerId",
                                                               date
                                                        FROM products) AS products
                                                       USING ("productId")),
                      distinct_samples AS (SELECT *,
                                                  LEAD(DATE)
                                                  OVER (PARTITION BY "coreProductId", "retailerId", category, "sourceCategoryId" ORDER BY DATE) AS date_till
                                           FROM products
                                           WHERE "productRank" IS DISTINCT FROM "prev_productRank"
                                              OR "featuredRank" IS DISTINCT FROM "prev_featuredRank")
                 SELECT "coreProductId"                                         AS id,
                        "retailerId",
                        ARRAY_AGG((
                                   DATERANGE(date::date, date_till::date, '[)'),
                                   CATEGORY,
                                   "categoryType",
                                   "parentCategory",
                                   "productRank",
                                   "sourceCategoryId",
                                   featured,
                                   "featuredRank",
                                   "taxonomyId"
                                      )::product_ranking_v2 ORDER BY DATE DESC) AS ranking
                 FROM distinct_samples
                 GROUP BY "coreProductId", "retailerId"),
     pricing AS (WITH products AS (SELECT "coreProductId",
                                          "retailerId",
                                          DATE,
                                          "basePrice",
                                          "shelfPrice",
                                          "promotedPrice",
                                          LAG("basePrice")
                                          OVER (PARTITION BY "coreProductId", "retailerId" ORDER BY DATE) AS "prev_basePrice",
                                          LAG("shelfPrice")
                                          OVER (PARTITION BY "coreProductId", "retailerId" ORDER BY DATE) AS "prev_shelfPrice",
                                          LAG("promotedPrice")
                                          OVER (PARTITION BY "coreProductId", "retailerId" ORDER BY DATE) AS "prev_promotedPrice"
                                   FROM products),
                      distinct_samples AS (SELECT *,
                                                  LEAD(DATE)
                                                  OVER (PARTITION BY "coreProductId", "retailerId" ORDER BY DATE) AS date_till
                                           FROM products
                                           WHERE "basePrice" IS DISTINCT FROM "prev_basePrice"
                                              OR "shelfPrice" IS DISTINCT FROM "prev_shelfPrice"
                                              OR "promotedPrice" IS DISTINCT FROM "prev_promotedPrice")
                 SELECT "coreProductId"                                                         AS id,
                        "retailerId",
                        ARRAY_AGG((DATERANGE(date::date, date_till::date, '[)'),
                                   "promotedPrice",
                                   "basePrice",
                                   "shelfPrice")::public.product_pricing_v2 ORDER BY date DESC) AS pricing
                 FROM distinct_samples
                 GROUP BY "coreProductId", "retailerId")
SELECT *
FROM pricing
         LEFT OUTER JOIN ranking USING (id, "retailerId")
         LEFT OUTER JOIN status USING (id, "retailerId");