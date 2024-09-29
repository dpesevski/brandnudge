/*
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


TO DO:  1) Handle table "productGroupCoreProducts"


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
*/


/*  pre-script, add missing constraints */
ALTER TABLE "coreProductBarcodes"
    ALTER
        COLUMN "coreProductId"
        SET NOT NULL;

ALTER TABLE "coreProductBarcodes"
    ADD CONSTRAINT coreProductBarcodes_coreProducts__fk
        FOREIGN KEY ("coreProductId") REFERENCES "coreProducts" (id);

ALTER TABLE "coreProductSourceCategories"
    ALTER COLUMN "coreProductId" SET NOT NULL;

DROP TABLE IF EXISTS staging.merge_log;
CREATE TABLE IF NOT EXISTS staging.merge_log
(
    id                                    serial
        PRIMARY KEY,

    "old_coreProductId"                   integer NOT NULL,
    "new_coreProductId"                   integer NOT NULL,

    "deleted_coreProduct"                 "coreProducts",

    "updated_products"                    integer[],

    "updated_coreProductBarcodes"         integer[],

    "updated_coreProductSourceCategories" integer[],
    "deleted_coreProductSourceCategories" "coreProductSourceCategories"[],

    "updated_productGroupCoreProducts"    integer[],
    "deleted_productGroupCoreProducts"    "productGroupCoreProducts"[],

    "updated_coreProductCountryData"      integer[],
    "deleted_coreProductCountryData"      "coreProductCountryData"[],

    "updated_taxonomyProducts"            integer[],
    "deleted_taxonomyProducts"            "taxonomyProducts"[],

    "updated_coreRetailers"               integer[],
    "deleted_coreRetailers"               "coreRetailers"[],

    "deleted_reviews"                     reviews[],
    "deleted_coreRetailerDates"           "coreRetailerDates"[],
    "deleted_coreRetailerTaxonomies"      "coreRetailerTaxonomies"[],

    "updated_bannersProducts"             int4range[],
    "updated_coreRetailerSources"         int4range[],

    "createAt"                            timestamptz DEFAULT CURRENT_TIMESTAMP
);


DROP FUNCTION IF EXISTS staging.merge(integer, integer);
CREATE OR REPLACE FUNCTION staging.merge("old_coreProductId" integer, "new_coreProductId" integer) RETURNS integer
    LANGUAGE plpgsql
AS
$$
DECLARE
    log_entry_id                          integer;
    "deleted_coreProduct"                 "coreProducts";
    "updated_products"                    integer[];
    "updated_coreProductBarcodes"         integer[];
    "updated_coreProductSourceCategories" integer[];
    "deleted_coreProductSourceCategories" "coreProductSourceCategories"[];
    "updated_productGroupCoreProducts"    integer[];
    "deleted_productGroupCoreProducts"    "productGroupCoreProducts"[];
    "updated_coreProductCountryData"      integer[];
    "deleted_coreProductCountryData"      "coreProductCountryData"[];
    "updated_taxonomyProducts"            integer[];
    "deleted_taxonomyProducts"            "taxonomyProducts"[];
    "updated_coreRetailers"               integer[];
    "deleted_coreRetailers"               "coreRetailers"[];
    "deleted_reviews"                     reviews[];
    "deleted_coreRetailerDates"           "coreRetailerDates"[];
    "deleted_coreRetailerTaxonomies"      "coreRetailerTaxonomies"[];
    "updated_bannersProducts"             int4range[];
    "updated_coreRetailerSources"         int4range[];

BEGIN
    IF NOT EXISTS(SELECT *
                  FROM "coreProducts"
                  WHERE id = "old_coreProductId") THEN
        RAISE EXCEPTION 'old coreProductId = % not found.', "old_coreProductId";
    END IF;

    IF NOT EXISTS (SELECT *
                   FROM "coreProducts"
                   WHERE id = "new_coreProductId") THEN
        RAISE EXCEPTION 'new coreProductId = % not found.', "new_coreProductId";
    END IF;

    /*  products */
    WITH upd AS (
        UPDATE products
            SET "coreProductId" = "new_coreProductId"
            WHERE "coreProductId" = "old_coreProductId"
            RETURNING id)
    SELECT ARRAY_AGG(id)
    INTO "updated_products"
    FROM upd;

    /*  coreProductBarcodes */
    WITH upd AS (
        UPDATE "coreProductBarcodes"
            SET "coreProductId" = "new_coreProductId"
            WHERE "coreProductId" = "old_coreProductId"
            RETURNING id)
    SELECT ARRAY_AGG(id)
    INTO "updated_coreProductBarcodes"
    FROM upd;


    /*  coreProductSourceCategories */
    /*  first delete records in conflict with the UQ constraint */
    WITH records_in_conflict AS (SELECT old.id
                                 FROM "coreProductSourceCategories" AS old
                                          INNER JOIN "coreProductSourceCategories" AS new
                                                     ON (old."coreProductId" = "old_coreProductId" AND
                                                         new."coreProductId" = "new_coreProductId" AND
                                                         old."sourceCategoryId" = new."sourceCategoryId")),
         deleted AS (
             DELETE
                 FROM "coreProductSourceCategories" USING records_in_conflict
                     WHERE "coreProductSourceCategories".id = records_in_conflict.id
                     RETURNING "coreProductSourceCategories".*) -- watchout on the order of the columns here to match the order of columns in table definition
    SELECT ARRAY_AGG(deleted)
    INTO "deleted_coreProductSourceCategories"
    FROM deleted;

    /*  now is safe to update the rest  */
    WITH upd AS (
        UPDATE "coreProductSourceCategories"
            SET "coreProductId" = "new_coreProductId"
            WHERE "coreProductId" = "old_coreProductId"
            RETURNING id)
    SELECT ARRAY_AGG(id)
    INTO "updated_coreProductSourceCategories"
    FROM upd;

    /*  productGroupCoreProducts    */
    WITH records_in_conflict AS (SELECT old.id
                                 FROM "productGroupCoreProducts" AS old
                                          INNER JOIN "productGroupCoreProducts" AS new
                                                     ON (old."coreProductId" = "old_coreProductId" AND
                                                         new."coreProductId" = "new_coreProductId" AND
                                                         old."productGroupId" = new."productGroupId")),
         deleted AS (
             DELETE
                 FROM "productGroupCoreProducts" USING records_in_conflict
                     WHERE "productGroupCoreProducts".id = records_in_conflict.id
                     RETURNING "productGroupCoreProducts".*) -- watchout on the order of the columns here to match the order of columns in table definition
    SELECT ARRAY_AGG(deleted)
    INTO "deleted_productGroupCoreProducts"
    FROM deleted;

    WITH upd AS (
        UPDATE "productGroupCoreProducts"
            SET "coreProductId" = "new_coreProductId"
            WHERE "coreProductId" = "old_coreProductId"
            RETURNING id)
    SELECT ARRAY_AGG(id)
    INTO "updated_productGroupCoreProducts"
    FROM upd;


    /*  coreProductCountryData  */
    WITH records_in_conflict AS (SELECT old.id
                                 FROM "coreProductCountryData" AS old
                                          INNER JOIN "coreProductCountryData" AS new
                                                     ON (old."coreProductId" = "old_coreProductId" AND
                                                         new."coreProductId" = "new_coreProductId" AND
                                                         old."countryId" = new."countryId")),
         deleted AS (
             DELETE
                 FROM "coreProductCountryData" USING records_in_conflict
                     WHERE "coreProductCountryData".id = records_in_conflict.id
                     RETURNING "coreProductCountryData".*) -- watchout on the order of the columns here to match the order of columns in table definition
    SELECT ARRAY_AGG(deleted)
    INTO "deleted_coreProductCountryData"
    FROM deleted;

    WITH upd AS (
        UPDATE "coreProductCountryData"
            SET "coreProductId" = "new_coreProductId"
            WHERE "coreProductId" = "old_coreProductId"
            RETURNING id)
    SELECT ARRAY_AGG(id)
    INTO "updated_coreProductCountryData"
    FROM upd;

    /*  taxonomyProducts */
    WITH records_in_conflict AS (SELECT old.id
                                 FROM "taxonomyProducts" AS old
                                          INNER JOIN "taxonomyProducts" AS new
                                                     ON (old."coreProductId" = "old_coreProductId" AND
                                                         new."coreProductId" = "new_coreProductId" AND
                                                         old."taxonomyId" = new."taxonomyId" AND
                                                         old."sourceId" = new."sourceId")),
         deleted AS (
             DELETE
                 FROM "taxonomyProducts" USING records_in_conflict
                     WHERE "taxonomyProducts".id = records_in_conflict.id
                     RETURNING "taxonomyProducts".*) -- watchout on the order of the columns here to match the order of columns in table definition
    SELECT ARRAY_AGG(deleted)
    INTO "deleted_taxonomyProducts"
    FROM deleted;

    WITH upd AS (
        UPDATE "taxonomyProducts"
            SET "coreProductId" = "new_coreProductId"
            WHERE "coreProductId" = "old_coreProductId"
            RETURNING id)
    SELECT ARRAY_AGG(id)
    INTO "updated_taxonomyProducts"
    FROM upd;

    /*  coreRetailers */
    /*  create a temporary table "records_in_conflict_coreRetailers" to update both the dependent tables and coreRetailers table */
    CREATE TEMPORARY TABLE "records_in_conflict_coreRetailers" ON COMMIT DROP AS
    SELECT old.id AS old_id, new.id AS new_id
    FROM "coreRetailers" AS old
             INNER JOIN "coreRetailers" AS new
                        ON (old."coreProductId" = "old_coreProductId" AND
                            new."coreProductId" = "new_coreProductId" AND
                            old."retailerId" = new."retailerId" AND
                            old."productId" = new."productId");

    /*  handle dependant tables first   */

    /*  reviews */
    WITH deleted AS (
        DELETE
            FROM reviews
                USING "records_in_conflict_coreRetailers" AS records_in_conflict
                WHERE reviews."coreRetailerId" = records_in_conflict.old_id
                RETURNING reviews.*)
    SELECT ARRAY_AGG(deleted)
    INTO deleted_reviews
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
           new_id,
           "reviewId",
           title,
           comment,
           rating,
           date,
           "createdAt",
           "updatedAt"
    FROM UNNEST(deleted_reviews)
             INNER JOIN "records_in_conflict_coreRetailers" AS records_in_conflict ON ("coreRetailerId" = old_id)
    ON CONFLICT ("coreRetailerId","reviewId")
        DO NOTHING;

    /*  coreRetailerDates */
    WITH deleted AS (
        DELETE
            FROM "coreRetailerDates"
                USING "records_in_conflict_coreRetailers" AS records_in_conflict
                WHERE "coreRetailerId" = old_id
                RETURNING "coreRetailerDates".*)
    SELECT ARRAY_AGG(deleted)
    INTO "deleted_coreRetailerDates"
    FROM deleted;


    /*  coreRetailerTaxonomies */
    WITH deleted AS (
        DELETE
            FROM "coreRetailerTaxonomies"
                USING "records_in_conflict_coreRetailers" AS records_in_conflict
                WHERE "coreRetailerTaxonomies"."coreRetailerId" = records_in_conflict.old_id
                RETURNING "coreRetailerTaxonomies".*)
    SELECT ARRAY_AGG(deleted)
    INTO "deleted_coreRetailerTaxonomies"
    FROM deleted;

    INSERT INTO "coreRetailerTaxonomies" (id,
                                          "coreRetailerId",
                                          "retailerTaxonomyId",
                                          "createdAt",
                                          "updatedAt")
    SELECT id,
           new_id,
           "retailerTaxonomyId",
           "createdAt",
           "updatedAt"
    FROM UNNEST("deleted_coreRetailerTaxonomies")
             INNER JOIN "records_in_conflict_coreRetailers" AS records_in_conflict ON ("coreRetailerId" = old_id)
    ON CONFLICT
        DO NOTHING;


    /*  bannersProducts */
    WITH updated AS (
        UPDATE "bannersProducts"
            SET "coreRetailerId" = records_in_conflict.new_id
            FROM "records_in_conflict_coreRetailers" AS records_in_conflict
            WHERE "bannersProducts"."coreRetailerId" = records_in_conflict.old_id
            RETURNING "bannersProducts".*) -- watchout on the order of the columns here to match the order of columns in table definition
    SELECT ARRAY_AGG(INT4RANGE(id, "coreRetailerId"))
    INTO "updated_bannersProducts"
    FROM updated;


    /*   coreRetailerSources */
    WITH updated AS (
        UPDATE
            "coreRetailerSources"
                SET "coreRetailerId" = records_in_conflict.new_id
                FROM "records_in_conflict_coreRetailers" AS records_in_conflict
                WHERE "coreRetailerSources"."coreRetailerId" = records_in_conflict.old_id
                RETURNING "coreRetailerSources".*) -- watchout on the order of the columns here to match the order of columns in table definition
    SELECT ARRAY_AGG(INT4RANGE(id, "coreRetailerId"))
    INTO "updated_coreRetailerSources"
    FROM updated;

    /*  handle coreRetailers   */
    WITH deleted AS (
        DELETE
            FROM "coreRetailers" USING "records_in_conflict_coreRetailers" AS records_in_conflict
                WHERE "coreRetailers".id = records_in_conflict.old_id
                RETURNING "coreRetailers".*) -- watchout on the order of the columns here to match the order of columns in table definition
    SELECT ARRAY_AGG(deleted)
    INTO "deleted_coreRetailers"
    FROM deleted;

    WITH upd AS (
        UPDATE "coreRetailers"
            SET "coreProductId" = "new_coreProductId"
            WHERE "coreProductId" = "old_coreProductId"
            RETURNING id)
    SELECT ARRAY_AGG(id)
    INTO "updated_coreRetailers"
    FROM upd;


    /*  coreProducts   */
    WITH deleted AS (
        DELETE
            FROM "coreProducts"
                WHERE id = "old_coreProductId"
                RETURNING *) -- watchout on the order of the columns here to match the order of columns in table definition
    SELECT *
    INTO "deleted_coreProduct"
    FROM deleted;


    INSERT INTO staging.merge_log("old_coreProductId", "new_coreProductId", "deleted_coreProduct", updated_products,
                                  "updated_coreProductBarcodes", "updated_coreProductSourceCategories",
                                  "deleted_coreProductSourceCategories", "updated_productGroupCoreProducts",
                                  "deleted_productGroupCoreProducts", "updated_coreProductCountryData",
                                  "deleted_coreProductCountryData", "updated_taxonomyProducts",
                                  "deleted_taxonomyProducts", "updated_coreRetailers", "deleted_coreRetailers",
                                  "deleted_reviews",
                                  "deleted_coreRetailerDates",
                                  "deleted_coreRetailerTaxonomies",
                                  "updated_bannersProducts",
                                  "updated_coreRetailerSources")
    VALUES ("old_coreProductId", "new_coreProductId", "deleted_coreProduct", updated_products,
            "updated_coreProductBarcodes", "updated_coreProductSourceCategories",
            "deleted_coreProductSourceCategories", "updated_productGroupCoreProducts",
            "deleted_productGroupCoreProducts", "updated_coreProductCountryData",
            "deleted_coreProductCountryData", "updated_taxonomyProducts",
            "deleted_taxonomyProducts", "updated_coreRetailers", "deleted_coreRetailers", "deleted_reviews",
            "deleted_coreRetailerDates",
            "deleted_coreRetailerTaxonomies",
            "updated_bannersProducts",
            "updated_coreRetailerSources")
    RETURNING id INTO log_entry_id;

    RETURN log_entry_id;
END
$$;

DROP FUNCTION IF EXISTS staging.reverse_merge(integer);
CREATE OR REPLACE FUNCTION staging.reverse_merge(merge_id integer) RETURNS void
    LANGUAGE plpgsql
AS
$$
DECLARE
    log staging.merge_log;
BEGIN

    SELECT *
    INTO log
    FROM staging.merge_log
    WHERE id = merge_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'merge id = % does not exist.', merge_id;
    END IF;

    /*  TO DO: We should check if any of the earlier merges relates to the coreProducts of this one, and then apply some logic to prevent creating inconsistency from this reverse.    */

    /*  coreProducts */
    INSERT INTO "coreProducts"
    SELECT (log."deleted_coreProduct").*;
    -- ON CONFLICT DO NOTHING;
    -- TO DO: REMOVE "ON CONFLICT DO NOTHING" WHEN ALL TABLES ARE IMPLEMENTED IN THE MERGE FUNCTION, WITH NO RELATED RECORDS LEFT SO COREPRODUCT RECORD CAN BE DELETED.

    /*  products */
    UPDATE products
    SET "coreProductId" = (log."old_coreProductId")
    WHERE id = ANY (log."updated_products");

    /*  coreProductBarcodes */
    UPDATE "coreProductBarcodes"
    SET "coreProductId" = (log."old_coreProductId")
    WHERE id = ANY (log."updated_coreProductBarcodes");

    /*  coreProductSourceCategories */
    UPDATE "coreProductSourceCategories"
    SET "coreProductId" = (log."old_coreProductId")
    WHERE id = ANY (log."updated_coreProductSourceCategories");

    WITH deleted_records AS (SELECT t.*
                             FROM UNNEST(log."deleted_coreProductSourceCategories") AS t)
    INSERT
    INTO "coreProductSourceCategories"
    SELECT *
    FROM deleted_records;


    /*  productGroupCoreProducts */
    UPDATE "productGroupCoreProducts"
    SET "coreProductId" = (log."old_coreProductId")
    WHERE id = ANY (log."updated_productGroupCoreProducts");

    WITH deleted_records AS (SELECT t.*
                             FROM UNNEST(log."deleted_productGroupCoreProducts") AS t)
    INSERT
    INTO "productGroupCoreProducts"
    SELECT *
    FROM deleted_records;

    /*  coreProductCountryData  */
    UPDATE "coreProductCountryData"
    SET "coreProductId" = (log."old_coreProductId")
    WHERE id = ANY (log."updated_coreProductCountryData");

    WITH deleted_records AS (SELECT t.*
                             FROM UNNEST(log."deleted_coreProductCountryData") AS t)
    INSERT
    INTO "coreProductCountryData"
    SELECT *
    FROM deleted_records;


    /*  coreProductCountryData  */
    UPDATE "taxonomyProducts"
    SET "coreProductId" = (log."old_coreProductId")
    WHERE id = ANY (log."updated_taxonomyProducts");

    WITH deleted_records AS (SELECT t.*
                             FROM UNNEST(log."deleted_taxonomyProducts") AS t)
    INSERT
    INTO "taxonomyProducts"
    SELECT *
    FROM deleted_records;


    /*  coreRetailers  */
    UPDATE "coreRetailers"
    SET "coreProductId" = (log."old_coreProductId")
    WHERE id = ANY (log."updated_coreRetailers");

    WITH deleted_records AS (SELECT t.*
                             FROM UNNEST(log."deleted_coreRetailers") AS t)
    INSERT
    INTO "coreRetailers"
    SELECT *
    FROM deleted_records;

    /*  update dependant tables to coreRetailers    */

    /*  reviews */
    WITH deleted_records AS (SELECT t.*
                             FROM UNNEST(log."deleted_reviews") AS t)
    INSERT
    INTO "reviews"
    SELECT *
    FROM deleted_records
    ON CONFLICT (id) DO UPDATE
        SET "coreRetailerId"=excluded."coreRetailerId";


    /*  coreRetailerDates */
    WITH deleted_records AS (SELECT t.*
                             FROM UNNEST(log."deleted_coreRetailerDates") AS t)
    INSERT
    INTO "coreRetailerDates"
    SELECT *
    FROM deleted_records;

    /*  coreRetailerTaxonomies */
    WITH deleted_records AS (SELECT t.*
                             FROM UNNEST(log."deleted_coreRetailerTaxonomies") AS t)
    INSERT
    INTO "coreRetailerTaxonomies"
    SELECT *
    FROM deleted_records
    ON CONFLICT (id) DO UPDATE
        SET "coreRetailerId"=excluded."coreRetailerId";

    /*  bannersProducts */
    WITH updated_records AS (SELECT LOWER(t) id, UPPER(t) AS "coreRetailerId"
                             FROM UNNEST(log."updated_bannersProducts") AS t)
    UPDATE "bannersProducts" AS table_to_update
    SET "coreRetailerId"=updated_records."coreRetailerId"
    FROM updated_records
    WHERE table_to_update.id = updated_records.id;

    /*  coreRetailerSources */
    WITH updated_records AS (SELECT LOWER(t) id, UPPER(t) AS "coreRetailerId"
                             FROM UNNEST(log."updated_coreRetailerSources") AS t)
    UPDATE "coreRetailerSources" AS table_to_update
    SET "coreRetailerId"=updated_records."coreRetailerId"
    FROM updated_records
    WHERE table_to_update.id = updated_records.id;


    /*  remove log entry. Maybe archive it?  */
    DELETE
    FROM staging.merge_log
    WHERE id = merge_id;

END
$$;


/*  tests   */
SELECT staging.merge(1306933, 752737);

SELECT *
FROM staging.merge_log;

SELECT *
FROM "coreProductCountryData"
WHERE id = 1126640;


SELECT "coreProductId"
FROM "coreProductSourceCategories"
WHERE id = 2872384;

WITH log AS (SELECT *
             FROM staging.merge_log
             WHERE id = 1),
     deleted_records AS (SELECT t.*
                         FROM log
                                  CROSS JOIN LATERAL UNNEST("deleted_coreProductSourceCategories") AS t)
SELECT *
FROM deleted_records;


SELECT *
FROM "coreProducts"
WHERE id = 1306933;

SELECT staging.reverse_merge(1);



