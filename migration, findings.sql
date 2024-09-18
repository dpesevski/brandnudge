/*
    same review (reviewId, content) for different, but similar coreProducts (title)
        created over different timestamps, but with same date, review title, comment and rating.
        Is this how re-load/re-visit data logic at a later date is implemented?
        Is it related to how different coreproducts with same sourceId are handled?
*/

SELECT *
FROM reviews
         INNER JOIN "coreRetailers" ON "coreRetailerId" = "coreRetailers".id
         INNER JOIN "coreProducts" ON "coreProductId" = "coreProducts".id
WHERE "reviewId" = '1000010';


/*
    1. "mappingLogs" records where coreProductId = suggestedProductId
    2. "mappingLogs" records where the suggested core product is merged one more time at a later date to another core product.
        This happens only once, i.e., there are no cases where a core product is merged 3 times in a row to a different core product.
*/
WITH merge_core_product AS (SELECT id,
                                   (log #>> '{coreProductId}')::integer                               AS "coreProductId",
                                   (log #>> '{coreProductProduct}')::integer                          AS "coreProductProduct",
                                   (log #>> '{suggestedProductId}')::integer                          AS "suggestedProductId",
                                   (log #>> '{suggestedProductProduct}')::integer                     AS "suggestedProductProduct",
                                   (log #>> '{match}')::float                                         AS "match",
                                   (log #>> '{matchTitle}')::float                                    AS "matchTitle",
                                   "createdAt",
                                   manual,
                                   ROW_NUMBER()
                                   OVER (PARTITION BY log #>> '{coreProductId}' ORDER BY "createdAt") AS version_no
                            FROM "mappingLogs"
                            WHERE log #>> '{coreProductId}' != log #>> '{suggestedProductId}')
SELECT m1."coreProductId",
       m1."suggestedProductProduct",
       m1."createdAt",
       m1.manual,
       m2."coreProductId",
       m2."suggestedProductProduct",
       m2."createdAt",
       m2.manual
FROM merge_core_product AS m1
         INNER JOIN merge_core_product AS m2 ON (m1."suggestedProductProduct" = m2."coreProductId")
--INNER JOIN merge_core_product AS m3 ON (m2."suggestedProductProduct" = m3."coreProductId")
;


WITH logging AS (SELECT log #>> '{coreProductId}'      AS "coreProductId",
                        log #>> '{suggestedProductId}' AS "suggestedProductId",
                        "createdAt"
                 FROM "mappingLogs")
SELECT logging."createdAt"         AS "mergedDate",
       "suggestedProductId",
       "coreProducts".id,
       "coreProducts"."disabled",
       "coreProducts"."createdAt"  AS "cpCreatedDate",
       "coreProducts"."updatedAt"  AS "cpUpdatedDate",
       "reviews"."createdAt"       AS "reviewDate",
       "coreRetailers"."createdAt" AS "crDate",
       "reviews".*
FROM "coreProducts"
         LEFT JOIN "coreRetailers" ON "coreProducts".id = "coreRetailers"."coreProductId"
         LEFT JOIN "reviews" ON "coreRetailers".id = "reviews"."coreRetailerId"
         LEFT JOIN logging ON "coreProducts".id::text = logging."coreProductId"
WHERE "productId" = '62852011'
  AND "reviews"."createdAt" >= logging."createdAt"
ORDER BY "coreProducts"."createdAt"