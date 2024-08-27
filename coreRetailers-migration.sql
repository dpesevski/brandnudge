WITH selection AS (SELECT "retailerId",
                          "coreProductId",
                          ARRAY_AGG("productId" ORDER BY "createdAt" DESC) AS "productIds"
                   FROM "coreRetailers"
                   GROUP BY "retailerId", "coreProductId"
                   HAVING COUNT(*) > 1),

     sel_ext AS (SELECT *,
                        "productId" != "productIds"[1] AS to_update
                 FROM "coreRetailers"
                          INNER JOIN selection USING ("retailerId", "coreProductId")
                 ORDER BY "retailerId", "coreProductId", "createdAt" DESC),

     records_to_keep AS (SELECT "retailerId",
                                "coreProductId",
                                id AS "new_coreRetailerId"
                         FROM sel_ext
                         WHERE NOT to_update),
     records_to_update AS (SELECT id AS "coreRetailerId", "new_coreRetailerId"
                           FROM sel_ext
                                    INNER JOIN records_to_keep USING ("retailerId", "coreProductId")
                           WHERE to_update)
SELECT COUNT(*)
FROM records_to_update
         INNER JOIN reviews USING ("coreRetailerId");



SELECT *,
       SUM(1) OVER (PARTITION BY "retailerId", "coreProductId")                                 AS group_id,
       ROW_NUMBER() OVER (PARTITION BY "retailerId", "coreProductId" ORDER BY "createdAt" DESC) AS version_no
FROM "coreRetailers"
ORDER BY "retailerId", "coreProductId", "createdAt" DESC
