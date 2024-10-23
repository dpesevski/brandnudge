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
    "mappingLogs"
    ============================================================
    1.  records where coreProductId = suggestedProductId
*/
CREATE TABLE test.merge_core_product AS
WITH "mappingLogs_base" AS (SELECT id,
                                   (log #>> '{coreProductId}')::integer           AS "coreProductId",
                                   (log #>> '{coreProductProduct}')::integer      AS "coreProductProduct",
                                   (log #>> '{suggestedProductId}')::integer      AS "suggestedProductId",
                                   (log #>> '{suggestedProductProduct}')::integer AS "suggestedProductProduct",
                                   (log #>> '{match}')::float                     AS "match",
                                   (log #>> '{matchTitle}')::float                AS "matchTitle",
                                   "createdAt",
                                   manual
                            FROM "mappingLogs"
                            WHERE log #>> '{coreProductId}' != log #>> '{suggestedProductId}'),
     merge_core_product AS (SELECT id                                                                AS merge_id,
                                   "coreProductId",
                                   "coreProductProduct",
                                   "suggestedProductId",
                                   "suggestedProductProduct",
                                   match,
                                   "matchTitle",
                                   "createdAt",
                                   manual,
                                   ROW_NUMBER()
                                   OVER (PARTITION BY "coreProductId" ORDER BY "createdAt")          AS version_no,
                                   DENSE_RANK()
                                   OVER (PARTITION BY "coreProductId" ORDER BY "suggestedProductId") AS "suggestedProductId_version_no",
                                   LAG("createdAt")
                                   OVER (PARTITION BY "coreProductId" ORDER BY "createdAt")          AS "previous_ts"
                            FROM "mappingLogs_base")
SELECT *
FROM merge_core_product
ORDER BY "coreProductId", version_no;

/*
    2.  records where the suggested core product is merged one more time at a later date to another core product.
        This happens only once, i.e., there are no cases where a core product is merged 3 times in a row to a different core product.
        There are related product records only for coreProductId=33815. Only 2 of these product records are dated after the mappingLogs date.
*/
SELECT m1."coreProductId",
       m1."suggestedProductProduct",
       m1."createdAt",
       m1.manual,
       m2."coreProductId",
       m2."suggestedProductProduct",
       m2."createdAt",
       m2.manual
FROM test.merge_core_product AS m1
         INNER JOIN test.merge_core_product AS m2 ON (m1."suggestedProductProduct" = m2."coreProductId");
--INNER JOIN test.merge_core_product AS m3 ON (m2."suggestedProductProduct" = m3."coreProductId")

/*
    3.  records where suggestedProductId changes over time
*/
WITH distinct_merge AS (SELECT DISTINCT "coreProductId", "suggestedProductId"
                        FROM test.merge_core_product),
     different_merge_over_time AS (SELECT "coreProductId"
                                   FROM distinct_merge
                                   GROUP BY 1
                                   HAVING COUNT(*) > 1)
SELECT *
FROM test.merge_core_product
         INNER JOIN different_merge_over_time USING ("coreProductId")
ORDER BY "coreProductId", "createdAt";

/*
    "mappingLogs"
    ============================================================

    use the latest record of each "coreProductId" for "suggestedProductId"("correct_coreProductId")

*/
DROP TABLE IF EXISTS test.merge_core_product_latest;
CREATE TABLE test.merge_core_product_latest AS
WITH "mappingLogs_base" AS (SELECT (log #>> '{coreProductId}')::integer                                    AS "coreProductId",
                                   (log #>> '{suggestedProductId}')::integer                               AS "correct_coreProductId",
                                   "createdAt",
                                   ROW_NUMBER()
                                   OVER (PARTITION BY log #>> '{coreProductId}' ORDER BY "createdAt" DESC) AS version_no
                            FROM "mappingLogs"
                            WHERE log #>> '{coreProductId}' != log #>> '{suggestedProductId}')
SELECT "coreProductId", "correct_coreProductId", "createdAt"
FROM "mappingLogs_base"
WHERE version_no = 1;

SELECT *
FROM test.merge_core_product_latest
         INNER JOIN products USING ("coreProductId")
WHERE products."createdAt" > merge_core_product_latest."createdAt"
