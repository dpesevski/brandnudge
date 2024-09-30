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

 */

-- set WORK_MEM = '1GB'

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

ALTER TABLE "coreRetailerSources"
    ADD CONSTRAINT coreRetailerSources_pk
        UNIQUE ("retailerId", "sourceId");

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
