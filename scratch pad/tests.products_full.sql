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
     ranking AS (SELECT "coreProductId"                                      AS id,
                        "retailerId",
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
                                      )::product_ranking ORDER BY date DESC) AS ranking
                 FROM "productsData"
                          INNER JOIN (SELECT id AS "productId",
                                             "coreProductId",
                                             "retailerId",
                                             date
                                      FROM products) AS products
                                     USING ("productId")
                 GROUP BY "coreProductId",
                          "retailerId"),
     pricing AS (SELECT "coreProductId"                                                               AS id,
                        "retailerId",
                        ARRAY_AGG((date,
                                   products."promotedPrice",
                                   products."basePrice",
                                   products."shelfPrice")::public.product_pricing ORDER BY date DESC) AS pricing
                 FROM products
                 GROUP BY "coreProductId",
                          "retailerId")
SELECT *
FROM "coreProducts"
         INNER JOIN pricing USING (id)
         LEFT OUTER JOIN status USING (id, "retailerId")
         LEFT OUTER JOIN ranking USING (id, "retailerId")