WITH selection AS (SELECT "retailerId",
                          "coreProductId",
                          ARRAY_AGG("productId" ORDER BY "createdAt" DESC) AS "productIds"
                   FROM "coreRetailers"
                   GROUP BY "retailerId", "coreProductId"
                   HAVING COUNT(*) > 1),

     "coreRetailers_base" AS (SELECT id,
                                     "coreProductId",
                                     "retailerId",
                                     "productId",
                                     "createdAt",
                                     "updatedAt",
                                     "productId" != "productIds"[1] AS to_update
                              FROM "coreRetailers"
                                       INNER JOIN selection USING ("retailerId", "coreProductId")
                              ORDER BY "retailerId", "coreProductId", "createdAt" DESC),

     records_to_keep AS (SELECT "retailerId",
                                "coreProductId",
                                id AS "new_coreRetailerId"
                         FROM "coreRetailers_base"
                         WHERE NOT to_update),
     records_to_update AS (SELECT id AS "coreRetailerId", "new_coreRetailerId"
                           FROM "coreRetailers_base"
                                    INNER JOIN records_to_keep USING ("retailerId", "coreProductId")
                           WHERE to_update)
SELECT COUNT(*)
FROM records_to_update
         INNER JOIN reviews USING ("coreRetailerId");


SELECT id,
       "coreRetailerId",
       "reviewId",
       title,
       comment,
       rating,
       date,
       "createdAt",
       "updatedAt"
FROM reviews;

SELECT id,
       "coreRetailerId",
       "retailerTaxonomyId",
       "createdAt",
       "updatedAt"
FROM "coreRetailerTaxonomies";

?!
20239655 count reviews
12712318 count reviews TO correct


