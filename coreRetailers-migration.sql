CREATE TEMPORARY TABLE records_to_update ON COMMIT DROP AS
WITH selection AS (SELECT "retailerId",
                          "coreProductId",
                          ARRAY_AGG("productId" ORDER BY "createdAt" DESC) AS "productIds"
                   FROM "coreRetailers"

                   GROUP BY "retailerId", "coreProductId"
                   HAVING COUNT(*) > 1),

     "coreRetailers_base" AS (SELECT id                            AS "coreRetailerId",
                                     "coreProductId",
                                     "retailerId",
                                     "productId",
                                     "createdAt",
                                     "updatedAt",
                                     "productIds",
                                     "productId" = "productIds"[1] AS is_most_recent_record
                              FROM "coreRetailers"
                                       INNER JOIN selection USING ("retailerId", "coreProductId")
                              ORDER BY "retailerId", "coreProductId", "createdAt" DESC),

     records_to_keep AS (SELECT "retailerId",
                                "coreProductId",
                                "coreRetailerId" AS "new_coreRetailerId"
                         FROM "coreRetailers_base"
                         WHERE is_most_recent_record)
SELECT "coreRetailerId", "new_coreRetailerId", "coreProductId", "retailerId"
FROM "coreRetailers_base"
         INNER JOIN records_to_keep USING ("retailerId", "coreProductId")
WHERE NOT is_most_recent_record;

/*
SELECT COUNT(*) /*   696.096 */
FROM records_to_update;

SELECT COUNT(*) /* 1.509.139 */
FROM "coreRetailers";
*/

WITH upd_reviews AS (SELECT "retailerId", "coreProductId", "new_coreRetailerId", reviews.*
                     FROM reviews
                              INNER JOIN records_to_update USING ("coreRetailerId")
                     UNION ALL
                     SELECT DISTINCT "retailerId",
                                     "coreProductId",
                                     reviews."coreRetailerId" AS "new_coreRetailerId",
                                     reviews.*
                     FROM reviews
                              INNER JOIN records_to_update
                                         ON (reviews."coreRetailerId" = records_to_update."new_coreRetailerId")),
     selection AS (SELECT "new_coreRetailerId", "reviewId"
                   FROM upd_reviews
                   GROUP BY "new_coreRetailerId", "reviewId"
                   HAVING COUNT(*) > 1)
SELECT *
FROM upd_reviews
         INNER JOIN selection USING ("new_coreRetailerId", "reviewId")
ORDER BY "new_coreRetailerId", "reviewId";



SELECT *
FROM reviews

WHERE "coreRetailerId" IN ('22619', '16453')
  AND "reviewId" = '969937';

SELECT *
FROM records_to_update
WHERE "new_coreRetailerId" = '22619'

SELECT COUNT(*)
FROM "bannersProducts"
         INNER JOIN records_to_update USING ("coreRetailerId");
DROP INDEX coreretailerid_reviewid_uniq;

CREATE TABLE "reviews_corrections" AS
SELECT *
FROM reviews
         INNER JOIN records_to_update USING ("coreRetailerId");

UPDATE reviews AS destination_table
SET "coreRetailerId" = "new_coreRetailerId"
FROM records_to_update
WHERE records_to_update."coreRetailerId" = destination_table."coreRetailerId";

CREATE TABLE "coreRetailerTaxonomies_corrections" AS
SELECT *
FROM "coreRetailerTaxonomies"
         INNER JOIN records_to_update USING ("coreRetailerId");

UPDATE "coreRetailerTaxonomies" AS destination_table
SET "coreRetailerId" = "new_coreRetailerId"
FROM records_to_update
WHERE records_to_update."coreRetailerId" = destination_table."coreRetailerId";

/*  2nd step for "coreRetailerTaxonomies"
    Previous update may produce multiple records with same "retailerTaxonomyId" for a given "coreRetailerId".
    These should be removed.
    However, within the existing data there are a number of cases where a single core product for a given retailer (coreRetailerId) is flagged with same retailerTaxonomyId in multiple records.

    SELECT id,
           "coreRetailerId",
           "retailerTaxonomyId",
           "createdAt",
           "updatedAt",
           ROW_NUMBER() OVER (PARTITION BY "coreRetailerId", "retailerTaxonomyId" ORDER BY "createdAt" DESC)
    FROM "coreRetailerTaxonomies"
    ORDER BY "coreRetailerId", "retailerTaxonomyId";
*/

CREATE TABLE "bannersProducts_corrections" AS
WITH corrections AS (
    UPDATE "bannersProducts" AS destination_table
        SET "coreRetailerId" = "new_coreRetailerId"
        FROM records_to_update
        WHERE records_to_update."coreRetailerId" = destination_table."coreRetailerId"
        RETURNING *)
SELECT *
FROM corrections;

CREATE TABLE "coreRetailerDates_corrections" AS
WITH corrections AS (
    DELETE
        FROM "coreRetailerDates" AS destination_table
            USING records_to_update
            WHERE records_to_update."coreRetailerId" = destination_table."coreRetailerId"
            RETURNING *)
SELECT *
FROM corrections;

CREATE TABLE "coreRetailers_corrections" AS
WITH corrections AS (
    DELETE
        FROM "coreRetailers" AS destination_table
            USING records_to_update
            WHERE records_to_update."coreRetailerId" = destination_table.id
            RETURNING *)
SELECT *
FROM corrections;

/*
SELECT *
FROM information_schema.columns
WHERE column_name = 'coreRetailerId'
  AND table_schema = 'public';

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

SELECT id,
       "productId",
       "bannerId",
       "createdAt",
       "updatedAt",
       "coreRetailerId"
FROM "bannersProducts";

SELECT id,
       "coreRetailerId",
       "dateId",
       "createdAt",
       "updatedAt"
FROM "coreRetailerDates";
*/


