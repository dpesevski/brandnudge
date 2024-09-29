-- set WORK_MEM = '8GB'
-- show WORK_MEM
/*
"coreProducts"
+---------------------------+-------------------------------------------------------------------------------------------+
|table_name                 | Comments                                                                                  |
+---------------------------+-------------------------------------------------------------------------------------------+
|products                   |
|taxonomyProducts           | no UQ constraint, but should be enforced to avoid duplicates after a merge.
|productGroupCoreProducts   | no NOT NULL constraint. no UQ constraint, but should be enforced to avoid duplicates after a merge.
                                            product groups are not used with coreProducts for the past 4 years
                                                SELECT *
                                                FROM "coreProducts"
                                                WHERE "productGroupId" IS NOT NULL
                                                ORDER BY "createdAt" DESC;

|coreProductBarcodes        | there is no NOT NULL constraint on coreProductId, and no FK to coreProducts. However, the data is ok, and these constraints can be added immediately,
|coreProductSourceCategories| FK to coreProducts exists, only add NOT NULL constraint. UQ constraint exist on ("sourceCategoryId", "coreProductId"). When merging, if a record with a ("sourceCategoryId", new "coreProductId") exists, the record being merged should be deleted.
|coreProductCountryData     | FK to coreProducts exists as well, add NOT NULL constraint. UQ constraint exist on ("coreProductId", "countryId"). When merging, if a record with a ("countryId", new "coreProductId") exists, the record being merged should be deleted.



|coreRetailers              | there is no NOT NULL constraint on coreProductId and no FK to coreProducts. One record relates to non-existing coreProductId(36693). Other then this constraints can be added immediately,
                                  There is UQ on ("coreProductId", "retailerId", "productId"). However, this table should split in 2
                                    - one, keeping the name but with UQ ("coreProductId", "retailerId"), and
                                    - additional one,  a copy of the original, with UQ on ("coreProductId", "retailerId", "productId").
                                  Most of the tables relating to coreRetailers are relating on the coreProduct, not the sourceId(productId).

TO DO:  1) Handle tables relating to "coreRetailers"
            - "reviews"
            - "coreRetailerDates"
            - "coreRetailerTaxonomies"
            - "bannersProducts"
            - **additional table, coreRetailerSources for linking all the sourceIds to a coreRetailer record (retailerId, coreProductId)

        These tables will not be updated in case coreRetailers is updated to link to a new coreProductId.
        They will only get updated in case the coreRetailer record is deleted (so we won't end up with duplicate coreProductId in coreRetailers for a single retailerId).
        It is most probable that this will be the only case, as the new coreProductId should already be present in the coreRetailers table.

        If the coreRetailers record gets deleted, the related records in the above tables will be updated to point to the new coreRetailerId (coreProduct).
        We will store the ids of these records, in a separate array within the deleted_coreRetailer record, so we can reverse it later if needed.

        The coreRetailer table will have a unique constraint for (retailerId, coreProductId).
        The additional table, coreRetailerSources, will have a unique constraint for the (retailerId, sourceId), i.e., a single sourceId (within a retailer)
            will always point only to only one coreRetailer (retailer, coreProduct).



NOT to be considered in the updates.
=============================
|mappingSuggestions         | This table has less records than mappingLogs (when counting distinct coreProductId,suggestedProductId)
|coreProductsOverride       | A small table, only 3 records. Looks like coreRetailers.
|coreProductTaggings        | An empty table. New feature?
+---------------------------+-------------------------------------------------------------------------------------------+

A) Fix failed merges
=============================

Table "mappingLogs" logs attempts to merge one coreProduct record to another coreProduct. It includes also the affected product records.
We should check if these merges were applied in full, i.e., find if the affected records in the above tables were updated to point to the new coreProductId.
If we find some of these records were not updated by the earlier merges, we should correct this, and apply the merge in full.

B)  coreProducts which have same titles and similar EANs


*/

/*
"coreRetailers"
===============================================================================
"coreRetailers" table is used both for:
    - linking products (coreProduct) to other source like reviews, coreRetailerTaxonomies, and
    - ingestion, to find the coreProduct by product's "sourceId", ("coreRetailers"."productId")

We need to separate the table so both functions will run properly.
As the table is viewed by the sourceId only from minor piece of code in the ingestion, it will be simpler if we keep the existing table only for the purpose of the first functionality,
i.e., keep a single UQ record per ("retailerId", "coreProductId"), which relates with the "coreRetailerId" in the other tables.
We will need to aggregate all the records with multiple occurrences of coreProductId into one, and store the sourceIds in a new table coreRetailerSources, including the retailerId.
"coreRetailer"  will have a unique constraint for (retailerId, coreProductId).
The additional table, "coreRetailerSources", will have field coreRetailerId to link to the table coreRetailers, and a unique constraint for the (retailerId, sourceId), i.e., a single sourceId (within a retailer)
    will always point only to only one coreRetailer (retailer, coreProduct).

Tables with an FK to "coreRetailers" ("coreRetailerId") (currently on coreRetailerDates and bannersProducts have an FK, but should be added for the rest) :
    - "reviews"
    - "coreRetailerDates"
    - "coreRetailerTaxonomies"
    - "bannersProducts"
  - **additional table, coreRetailerSources for linking all the sourceIds to a coreRetailer record (retailerId, coreProductId)

    1. Add UQ constraint ("retailerId", "coreProductId") in "coreRetailers":
    2. move "sourceId"(s) to a new table "coreRetailerSources".
        At any given time, a "sourceId" can point only to a single "coreProductId", so there should be a UQ constraint on the "active"/current ("sourceId", "coreProductId").
        If a "sourceId" pointed to more than one "coreProductid", only the latest coreProductId will be kept as active. The previous versions can be archived.
    3.  update above tables "coreRetailerId" with a new "new_coreRetailerId".
         "new_coreRetailerId" is the record which remained in coreRetailers for a ("retailerId", "coreProductId") after applying the UQ constraint.
        3.1. update records in the 4 tables, but prevent from creating duplicates after the update, i.e., delete a record if there is already a record with the "new_coreRetailerId".

NOTES:  If "sourceId" pointed to ane "coreProduct" and later to another, see if the two coreProducts merged ("mappingLogs"). This will be handled later in case C).
        Otherwise, the reviews (and the other tables), which were created before the change, should point to the old coreProduct, and after to the new coreProduct.

 /*
    update "coreRetailersId" ("coreProductid") in Reviews (and other 3 tables?) for coreProducts which were to be merged with another coreProduct ("mappingLogs").
    Look for the latest coreProduct a specific product was to be merged into (can have more than one merges), and apply this one as a coreRetailerId.
*/

===============================================================================


 */


--CREATE TEMPORARY TABLE records_to_update ON COMMIT DROP AS
DROP TABLE IF EXISTS records_to_update;
CREATE TABLE records_to_update AS
WITH retailers_selection2("retailerId") AS (VALUES (3), -- sainsburys
                                                   (8), -- ocado
                                                   (10) -- waitrose
),
     retailers_selection("retailerId") AS (SELECT id AS "retailerId"
                                           FROM retailers),
     ret_prod_selection AS (SELECT "retailerId",
                                   "coreProductId",
                                   ARRAY_AGG("productId" ORDER BY "createdAt" DESC) AS "productIds"
                            FROM "coreRetailers"
                                     INNER JOIN retailers_selection USING ("retailerId")
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
                                       INNER JOIN ret_prod_selection USING ("retailerId", "coreProductId")
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
SELECT COUNT(*)
FROM records_to_update;

SELECT COUNT(*)
FROM "coreRetailers";
*/
/*
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
*/
/*
SELECT COUNT(*)
FROM "bannersProducts"
         INNER JOIN records_to_update USING ("coreRetailerId");
 */


/*
ALTER TABLE reviews
    ADD CONSTRAINT uq_coreretailerid_reviewid UNIQUE USING INDEX coreretailerid_reviewid_uniq DEFERRABLE;
ALTER TABLE "coreRetailerTaxonomies"
    ADD CONSTRAINT uq_coreretailertaxonomies_coreretailerid_retailertaxonomyid UNIQUE USING INDEX coreretailertaxonomies_coreretailerid_retailertaxonomyid_uq DEFERRABLE;
*/

/*
ALTER TABLE "coreRetailerDates"
    ALTER CONSTRAINT "coreRetailerDates_coreRetailerId_fkey" DEFERRABLE;
ALTER TABLE "bannersProducts"
    ALTER CONSTRAINT "bannersProducts_coreRetailerId_fkey" DEFERRABLE;
ALTER TABLE "coreRetailerDates"
    ALTER CONSTRAINT "coreRetailerDates_dateId_fkey" DEFERRABLE;

SET CONSTRAINTS ALL DEFERRED;
*/


/*
 20032196 all reviews
 640,024 rows deleted
 620,298 rows inserted
 */
DROP TABLE IF EXISTS "reviews_corrections";
CREATE TABLE "reviews_corrections" AS
WITH deleted AS (
    DELETE
        FROM reviews
            USING records_to_update
            WHERE reviews."coreRetailerId" = records_to_update."coreRetailerId"
            RETURNING reviews.*, "new_coreRetailerId")
SELECT *
FROM deleted;

INSERT INTO reviews (id,
                     "coreRetailerId",
                     "reviewId",
                     title,
                     comment,
                     rating,
                     date,
                     "createdAt",
                     "updatedAt")
SELECT id,
       "new_coreRetailerId",
       "reviewId",
       title,
       comment,
       rating,
       date,
       "createdAt",
       "updatedAt"
FROM reviews_corrections
ON CONFLICT ("coreRetailerId","reviewId")
    DO NOTHING;



DROP TABLE IF EXISTS "coreRetailerTaxonomies_corrections";
CREATE TABLE "coreRetailerTaxonomies_corrections" AS
WITH deleted AS (
    DELETE
        FROM "coreRetailerTaxonomies"
            USING records_to_update
            WHERE "coreRetailerTaxonomies"."coreRetailerId" = records_to_update."coreRetailerId"
            RETURNING "coreRetailerTaxonomies".*, "new_coreRetailerId")
SELECT *
FROM deleted;

INSERT INTO "coreRetailerTaxonomies" (id,
                                      "coreRetailerId",
                                      "retailerTaxonomyId",
                                      "createdAt",
                                      "updatedAt")
SELECT id,
       "new_coreRetailerId",
       "retailerTaxonomyId",
       "createdAt",
       "updatedAt"
FROM "coreRetailerTaxonomies_corrections"
ON CONFLICT DO NOTHING;


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
    UPDATE "bannersProducts"
        SET "coreRetailerId" = "new_coreRetailerId"
        FROM records_to_update
        WHERE records_to_update."coreRetailerId" = "bannersProducts"."coreRetailerId"
        RETURNING "bannersProducts".*)
SELECT *
FROM corrections;

CREATE TABLE "coreRetailerDates_corrections" AS
WITH corrections AS (
    DELETE
        FROM "coreRetailerDates"
            USING records_to_update
            WHERE records_to_update."coreRetailerId" = "coreRetailerDates"."coreRetailerId"
            RETURNING "coreRetailerDates".*)
SELECT *
FROM corrections;


DROP TABLE IF EXISTS public."coreRetailerSources";
CREATE TABLE public."coreRetailerSources"
(
    id               serial PRIMARY KEY,
    "coreRetailerId" integer,
    "retailerId"     integer,
    "sourceId"       varchar(255),
    "createdAt"      timestamptz DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"      timestamptz DEFAULT CURRENT_TIMESTAMP
);
WITH selection AS (SELECT COALESCE(records_to_update."new_coreRetailerId", "coreRetailers".id)       AS "coreRetailerId",
                          "coreRetailers"."retailerId",
                          "coreRetailers"."productId"                                                AS "sourceId",
                          ROW_NUMBER() OVER (PARTITION BY "coreRetailers"."retailerId",
                              "coreRetailers"."productId" ORDER BY "coreRetailers"."updatedAt" DESC) AS version_no
                   FROM "coreRetailers"
                            LEFT OUTER JOIN records_to_update
                                            ON (records_to_update."coreRetailerId" = "coreRetailers".id))
INSERT
INTO "coreRetailerSources" ("coreRetailerId", "retailerId", "sourceId")
SELECT "coreRetailerId", "retailerId", "sourceId"
FROM selection
WHERE version_no = 1;

/*
-- no longer relevant as only the latest occurrence of sourceId in coreRetailers is considered.

DROP TABLE IF EXISTS staging."duplicates_coreRetailerSources";
CREATE TABLE staging."duplicates_coreRetailerSources" AS
WITH duplicates AS (SELECT "retailerId", "sourceId"
                    FROM "coreRetailerSources"
                    GROUP BY "retailerId", "sourceId"
                    HAVING COUNT(*) > 1),
     deleted AS (

         DELETE
             FROM "coreRetailerSources" USING duplicates
                 WHERE "coreRetailerSources"."retailerId" = duplicates."retailerId"
                     AND "coreRetailerSources"."sourceId" = duplicates."sourceId"
                 RETURNING "coreRetailerSources".*)
SELECT *
FROM deleted;
*/

/* TO DO:   Handle cases where a single sourceId links to multiple coreProducts in coreRetailers
            As a possible solution, include these earlier in the records_to_update, so all coreRetailers records are handled (deleted) at once.

            As another possible solution, only use the latest occurence of sourceId in coreRetailers to fill in the coreReatilerSources.
            This will be the solution for now.
SELECT *
FROM staging."duplicates_coreRetailerSources"
         INNER JOIN "coreRetailers" ON ("coreRetailers".id = "coreRetailerId")
ORDER BY "duplicates_coreRetailerSources"."retailerId", "duplicates_coreRetailerSources"."sourceId";
   */

ALTER TABLE "coreRetailerSources"
    ADD CONSTRAINT coreRetailerSources_pk
        UNIQUE ("retailerId", "sourceId");

/*  times out  */

ALTER TABLE "coreRetailerDates"
    DROP CONSTRAINT "coreRetailerDates_coreRetailerId_fkey";
ALTER TABLE "bannersProducts"
    DROP CONSTRAINT "bannersProducts_coreRetailerId_fkey";

CREATE TABLE "coreRetailers_corrections" AS
WITH corrections AS (
    DELETE
        FROM "coreRetailers"
            USING records_to_update
            WHERE records_to_update."coreRetailerId" = "coreRetailers".id
            RETURNING "coreRetailers".*)
SELECT *
FROM corrections;

ALTER TABLE public."coreRetailerDates"
    ADD FOREIGN KEY ("coreRetailerId") REFERENCES public."coreRetailers"
        ON DELETE CASCADE
        DEFERRABLE;

ALTER TABLE "bannersProducts"
    ADD FOREIGN KEY ("coreRetailerId") REFERENCES "coreRetailers" DEFERRABLE;


/*
NO FK
coreRetailerTaxonomies
reviews

EXISTING FK
coreRetailerDates
bannersProducts

*/

ALTER TABLE "coreRetailers"
    DROP CONSTRAINT core_retailers_unique;

CREATE TABLE staging."backup_coreRetailers_productId" AS
SELECT id, "productId"
FROM "coreRetailers";

ALTER TABLE "coreRetailers"
    DROP COLUMN "productId";

ALTER TABLE "coreRetailers"
    ADD CONSTRAINT coreRetailers_pk
        UNIQUE ("coreProductId", "retailerId");
ALTER TABLE "coreRetailers"
    ADD CONSTRAINT coreRetailers_pk2
        UNIQUE ("id", "retailerId");

ALTER TABLE "coreRetailerSources"
    ADD CONSTRAINT coreRetailerSources_coreRetailers_id_retailerId_fk
        FOREIGN KEY ("coreRetailerId", "retailerId") REFERENCES "coreRetailers" (id, "retailerId");


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


alter table records_to_update RENAME to "data_corr_records_to_update";
alter table "coreRetailers_corrections" RENAME to "data_corr_affected_coreRetailers";
alter table "reviews_corrections" RENAME to "data_corr_affected_reviews";
alter table "coreRetailerDates_corrections" RENAME to "data_corr_affected_coreRetailerDates";
alter table "coreRetailerTaxonomies_corrections" RENAME to "data_corr_affected_coreRetailerTaxonomies";
alter table "bannersProducts_corrections" RENAME to "data_corr_affected_bannersProducts";

alter table "data_corr_records_to_update" SET SCHEMA staging;
alter table "data_corr_affected_coreRetailers" SET SCHEMA staging;
alter table "data_corr_affected_reviews" SET SCHEMA staging;
alter table "data_corr_affected_coreRetailerDates" SET SCHEMA staging;
alter table "data_corr_affected_coreRetailerTaxonomies" SET SCHEMA staging;
alter table "data_corr_affected_bannersProducts" SET SCHEMA staging;
