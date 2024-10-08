/*
Fix "coreRetailers" structure and adjust the data
===============================================================================

Background
========================
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

Tables referencing "coreRetailers" ("coreRetailerId"):  (**reviews and coreRetailerTaxonomies do not have an FK defined in the schema. should be added)
    - "reviews"
    - "coreRetailerTaxonomies"
    - "coreRetailerDates"
    - "bannersProducts"
  - **additional table, coreRetailerSources for linking all the sourceIds to a coreRetailer record (retailerId, coreProductId)

    1. Add UQ constraint ("retailerId", "coreProductId") in "coreRetailers":
    2. move "sourceId"(s) to a new table "coreRetailerSources".
        At any given time, a "sourceId" can point only to a single "coreProductId", so there should be a UQ constraint on the "active"/current ("sourceId", "coreProductId").
        If a "sourceId" pointed to more than one "coreProductid", only the latest coreProductId will be kept as active. The previous versions can be archived.
    3.  update above tables "coreRetailerId" with a new "new_coreRetailerId".
         "new_coreRetailerId" is the record which remained in coreRetailers for a ("retailerId", "coreProductId") after applying the UQ constraint.
        3.1. update records in the 5 tables, but prevent from creating duplicates after the update, i.e., delete a record if there is already a record with the "new_coreRetailerId".


Implementation
========================
The script makes the following changes in the data structure:
 - adds a new table "coreRetailerSources", for keeping retailer's "sourceId"s separately, with a
    - UQ constraint on "sourceId", and
    - referential constraint on "coreRetailers" ("coreRetailerId", "retailerId"). The "retailerId" is added to enforce records from the two tables relate to same retailerId.
- "coreRetailers"
    - adds UQ constraints for on ("coreProductId", "retailerId") and ("id", "retailerId"). The last one is added for the referential constraint on coreRetailerSources.
    - drop attribute "productId" as "productId" are migrated to "coreRetailerSources".

The script makes the following updates in the data to adjust it to the new structures:
 - keeps the latest version of "coreRetailers" records for each ("retailerId", "coreProductId"). The rest of the records/versions are removed.
 - records in the related tables which pointed to the coreRetailerIds which will be removed are handled in the following way:
    - "reviews", "coreRetailerTaxonomies" and "coreRetailerDates" have a UQ constraint on coreRetailerId with reviewId /retailerTaxonomyId/dateId. The script will try to update the related record to point to the new "coreRetailerId", however, in case are record already exists relating to the new coreRetailerId with same reviewId/retailerTaxonomyId/dateId, the record will not be updated and will be deleted.
    - "bannersProducts" does not have UQ constraints, so these records are only updated. Maybe we should review this at another run of fixes.

The affected records are backup in staging in "data_corr_affected_*" tables.

coreRetailers	                        926,948
coreRetailerSources	                    899,725

updates_part1_from_sourceId	            27,223 	`
updates_part2_from_coreProductId	    16,464
part2  & part1	    (1,198)
=====================================================
                                total:  43,687

 */

SET WORK_MEM = '2GB';
CREATE SCHEMA IF NOT EXISTS staging;

/*
Refactoring the creation of "coreRetailerSources" and selecting coreRetailers records which we'll handle later ("records_to_update")
===========================================================================================================================================
1) we first  create "coreRetailersSources", to have all the different sourceIds from coreRetailrs.
    - the coreRetailerId here will point to the latest record in coreRetailers relating to a non-disabled coreProduct. If all coreRetailers records point to disabled coreProducts, then the latest of them is selected.
    - every other record in coreRetailers is subject to be replaced with the one in coreRetailerSources matching its sourceId (productId). Technically, if we remove the rest of the records in coreRetailers, only one record per sourceId will remain, and coreRetailers records will match 1-1 with the ones in coreRetailersSources.
    - we use the selected records in coreRetailers (as stored now in "coreRetailersSources") and put these in the records_to_update table.
2) the next part of the updates is focusing on the remaining records in coreRetailers with same coreProductId
    - the latest versions are kept, and the rest are put in the records_to_update, as a 2nd selection of records to update
    - as there are records in coreRetailers which will be part of both updates, first from the sourceIds and later from the coreProductids, the two selections are merged into one, using a temporary table "updates_part2_from_coreProductId".
    - the "updates_part2_from_coreProductId" is
        - first used to update the "coreRetailersSources", and then the initial records in records_to_update to point to the final new coreRetailerId, and finaly
        - its records are pushed into records_to_update as a second batch of coreRetailers records to updte

The end result in records_to_update is thus all the coreRetailers records which will need to be handled later in the script. First we use these to update the related tables (reviews, coreRetailerTaxonomies...) to link to the new coreRetailerId, and at the end to remove the records in coreRetailers.

*/
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

-- missing coreProductId (id=36693) for coreRetailers(id=36137)
WITH disabled_core_products AS (SELECT id AS "coreProductId", disabled
                                FROM "coreProducts"),
     "coreRetailerSources_base" AS (SELECT "coreRetailers".id                                                                              AS "coreRetailerId",
                                           "coreRetailers"."retailerId",
                                           "coreRetailers"."productId"                                                                     AS "sourceId",
                                           ROW_NUMBER() OVER (PARTITION BY "coreRetailers"."retailerId",
                                               "coreRetailers"."productId" ORDER BY disabled NULLS LAST, "coreRetailers"."updatedAt" DESC) AS version_no
                                    FROM "coreRetailers"
                                             LEFT OUTER JOIN disabled_core_products USING ("coreProductId"))
INSERT
INTO "coreRetailerSources" ("coreRetailerId", "retailerId", "sourceId")
SELECT "coreRetailerId", "retailerId", "sourceId"
FROM "coreRetailerSources_base"
WHERE version_no = 1;

ALTER TABLE "coreRetailerSources"
    ADD CONSTRAINT coreRetailerSources_pk
        UNIQUE ("retailerId", "sourceId");


DROP TABLE IF EXISTS records_to_update;
/*  updates part1 from sourceId */
CREATE TABLE records_to_update AS
SELECT to_keep."retailerId",
       --to_keep."sourceId",
       to_update."coreProductId",
       to_update.id             AS "coreRetailerId",
       to_keep."coreRetailerId" AS "new_coreRetailerId"
FROM "coreRetailers" AS to_update
         INNER JOIN "coreRetailerSources" AS to_keep
                    ON (to_update."retailerId" = to_keep."retailerId"
                        AND to_update."productId" = to_keep."sourceId"
                        AND to_update.id != to_keep."coreRetailerId");


/*  updates part2 from coreProductId */
DROP TABLE IF EXISTS "updates_part2_from_coreProductId";
CREATE TABLE "updates_part2_from_coreProductId" AS
WITH "coreRetailerIds_within_coreRetailerSources" AS (SELECT "coreRetailerSources"."coreRetailerId" AS id
                                                      FROM "coreRetailerSources"),
     "kept_coreRetailers_after_updates_part1" AS (SELECT id                                             AS "coreRetailerId",
                                                         "retailerId",
                                                         "coreProductId",
                                                         ROW_NUMBER() OVER (PARTITION BY "retailerId",
                                                             "coreProductId" ORDER BY "updatedAt" DESC) AS version_no
                                                  FROM "coreRetailers"
                                                           INNER JOIN "coreRetailerIds_within_coreRetailerSources" USING (id)),
     to_keep AS (SELECT *
                 FROM "kept_coreRetailers_after_updates_part1"
                 WHERE version_no = 1),
     to_update AS (SELECT *
                   FROM "kept_coreRetailers_after_updates_part1"
                   WHERE version_no > 1)
SELECT "retailerId",
       "coreProductId",
       to_update."coreRetailerId",
       to_keep."coreRetailerId" AS "new_coreRetailerId"
FROM to_update
         INNER JOIN to_keep USING ("retailerId", "coreProductId");


/*  update "coreRetailerSources" records which link to same coreProductId in coreRetailers */
UPDATE "coreRetailerSources"
SET "coreRetailerId"="updates_part2_from_coreProductId"."new_coreRetailerId"
FROM "updates_part2_from_coreProductId"
WHERE "coreRetailerSources"."coreRetailerId" = "updates_part2_from_coreProductId"."coreRetailerId";


/*  determine final new_coreRetailerId after updates from sourceId and then from coreProductId */
UPDATE records_to_update
SET "new_coreRetailerId"="updates_part2_from_coreProductId"."new_coreRetailerId"
FROM "updates_part2_from_coreProductId"
WHERE records_to_update."new_coreRetailerId" = "updates_part2_from_coreProductId"."coreRetailerId";

ALTER TABLE records_to_update
    ADD CONSTRAINT records_to_update_uq UNIQUE ("retailerId", "coreRetailerId");

INSERT INTO records_to_update ("retailerId", "coreProductId", "coreRetailerId", "new_coreRetailerId")
SELECT "retailerId", "coreProductId", "coreRetailerId", "new_coreRetailerId"
FROM "updates_part2_from_coreProductId";

DROP TABLE "updates_part2_from_coreProductId";


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

/*  reviews */
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


/*  coreRetailerTaxonomies  */
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

/*  COMMENT ON "coreRetailerTaxonomies"

    Updates in coreRetailers may produce multiple records with same "retailerTaxonomyId" for a given "coreRetailerId".
    The above statements delete these records.
    However, outside of these updates, within the existing data there are a number of cases where a single core product for a given retailer (coreRetailerId) is flagged with same retailerTaxonomyId in multiple records.

    SELECT id,
           "coreRetailerId",
           "retailerTaxonomyId",
           "createdAt",
           "updatedAt",
           ROW_NUMBER() OVER (PARTITION BY "coreRetailerId", "retailerTaxonomyId" ORDER BY "createdAt" DESC)
    FROM "coreRetailerTaxonomies"
    ORDER BY "coreRetailerId", "retailerTaxonomyId";
*/

CREATE TABLE "coreRetailerDates_corrections" AS
WITH corrections AS (
    DELETE
        FROM "coreRetailerDates"
            USING records_to_update
            WHERE records_to_update."coreRetailerId" = "coreRetailerDates"."coreRetailerId"
            RETURNING "coreRetailerDates".*, "new_coreRetailerId")
SELECT *
FROM corrections;

INSERT INTO "coreRetailerDates" (id, "coreRetailerId", "dateId", "createdAt", "updatedAt")
SELECT id,
       "new_coreRetailerId",
       "dateId",
       "createdAt",
       "updatedAt"
FROM "coreRetailerDates_corrections"
ON CONFLICT DO NOTHING;

CREATE TABLE "bannersProducts_corrections" AS
WITH corrections AS (
    UPDATE "bannersProducts"
        SET "coreRetailerId" = "new_coreRetailerId"
        FROM records_to_update
        WHERE records_to_update."coreRetailerId" = "bannersProducts"."coreRetailerId"
        RETURNING "bannersProducts".*)
SELECT *
FROM corrections;


/*  coreRetailerDates_coreRetailerId_fkey constraint includes the clause to cascade the updates from "coreRetailers"
    The referential constraints ore temporary disabled, during this transaction, to speed the update.
    Later, the same are restored.

    As an alternative, we could deffer the checks for the end of the transaction, but then will need to execute the changes in the coreRetailers structure in another transaction.
*/
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


/*
+---------+--------------+------+
|id       |coreRetailerId|dateId|
+---------+--------------+------+
|264872436|769669        |28948 |
|264874622|984897        |28948 |
|264872349|642268        |28948 |
|264873228|3428369       |28948 |
|264873265|3428408       |28948 |
|264876342|986023        |28948 |
|264873343|986942        |28948 |
+---------+--------------+------+


WITH corrections AS (
    DELETE
        FROM "coreRetailerDates"
            USING records_to_update
            WHERE records_to_update."coreRetailerId" = "coreRetailerDates"."coreRetailerId" AND
                  records_to_update."coreRetailerId" IN (769669,
                                                         984897,
                                                         642268,
                                                         3428369,
                                                         3428408,
                                                         986023,
                                                         986942
                      )
            RETURNING "coreRetailerDates".*, "new_coreRetailerId")
INSERT
INTO "coreRetailerDates_corrections"
SELECT *
FROM corrections;

INSERT INTO "coreRetailerDates" (id, "coreRetailerId", "dateId", "createdAt", "updatedAt")
SELECT id,
       "new_coreRetailerId",
       "dateId",
       "createdAt",
       "updatedAt"
FROM "coreRetailerDates_corrections"
WHERE "coreRetailerId" IN (769669,
                           984897,
                           642268,
                           3428369,
                           3428408,
                           986023,
                           986942
    )
ON CONFLICT DO NOTHING;



SELECT "coreRetailerDates".*
FROM "coreRetailerDates"
         INNER JOIN records_to_update USING ("coreRetailerId")
WHERE "coreRetailerId" IN (769669,
                           984897,
                           642268,
                           3428369,
                           3428408,
                           986023,
                           986942
    );

 */


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
/*

WITH "coreRetailers_v_no" AS (SELECT *,
                                     ROW_NUMBER()
                                     OVER (PARTITION BY "coreProductId", "retailerId" ORDER BY "updatedAt" DESC) AS version_no
                              FROM "coreRetailers")
SELECT *
FROM "coreRetailers_v_no"
WHERE version_no = 2;
+--------+-------------+----------+---------------------------------+---------------------------------+----------+
|id      |coreProductId|retailerId|createdAt                        |updatedAt                        |version_no|
+--------+-------------+----------+---------------------------------+---------------------------------+----------+
|10219943|1334227      |1071      |2024-10-04 09:26:36.970330 +00:00|2024-10-04 09:26:36.970330 +00:00|2         |
+--------+-------------+----------+---------------------------------+---------------------------------+----------+


select * from "coreRetailerSources" where "coreRetailerId"=10219943;
select * from "reviews" where "coreRetailerId"=10219943;
select * from "coreRetailerDates" where "coreRetailerId"=10219943;
select * from "coreRetailerTaxonomies" where "coreRetailerId"=10219943;
select * from "bannersProducts" where "coreRetailerId"=10219943;

delete from "coreRetailerDates" where "coreRetailerId"=10219943;
delete from "coreRetailers" where id=10219943;
*/

ALTER TABLE "coreRetailers"
    ADD CONSTRAINT coreRetailers_pk2
        UNIQUE ("id", "retailerId");

ALTER TABLE "coreRetailerSources"
    ADD CONSTRAINT coreRetailerSources_coreRetailers_id_retailerId_fk
        FOREIGN KEY ("coreRetailerId", "retailerId") REFERENCES "coreRetailers" (id, "retailerId");


ALTER TABLE records_to_update
    RENAME TO "data_corr_records_to_update";
ALTER TABLE "coreRetailers_corrections"
    RENAME TO "data_corr_affected_coreRetailers";
ALTER TABLE "reviews_corrections"
    RENAME TO "data_corr_affected_reviews";
ALTER TABLE "coreRetailerDates_corrections"
    RENAME TO "data_corr_affected_coreRetailerDates";
ALTER TABLE "coreRetailerTaxonomies_corrections"
    RENAME TO "data_corr_affected_coreRetailerTaxonomies";
ALTER TABLE "bannersProducts_corrections"
    RENAME TO "data_corr_affected_bannersProducts";

ALTER TABLE "data_corr_records_to_update"
    SET SCHEMA staging;
ALTER TABLE "data_corr_affected_coreRetailers"
    SET SCHEMA staging;
ALTER TABLE "data_corr_affected_reviews"
    SET SCHEMA staging;
ALTER TABLE "data_corr_affected_coreRetailerDates"
    SET SCHEMA staging;
ALTER TABLE "data_corr_affected_coreRetailerTaxonomies"
    SET SCHEMA staging;
ALTER TABLE "data_corr_affected_bannersProducts"
    SET SCHEMA staging;
