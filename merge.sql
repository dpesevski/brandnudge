/*
+---------------------------+-----------+-------------------------------------------------------------------------------------------+
|table_name                 |is_nullable| Comments                                                                                  |
+---------------------------+-----------+-------------------------------------------------------------------------------------------+
|products                   |NO         |
|taxonomyProducts           |NO         | no UQ constraint, but should be enforced to avoid duplicates after a merge.
|productGroupCoreProducts   |YES        | no NOT NULL constraint. no UQ constraint, but should be enforced to avoid duplicates after a merge.
                                            product groups are not used with coreProducts for the past 4 years
                                                SELECT *
                                                FROM "coreProducts"
                                                WHERE "productGroupId" IS NOT NULL
                                                ORDER BY "createdAt" DESC;

|coreProductBarcodes        |YES        | there is no NOT NULL constraint on coreProductId, and no FK to coreProducts. However, the data is ok, and these constraints can be added immediately,
|coreProductSourceCategories|YES        | FK to coreProducts exists, only add NOT NULL constraint. UQ constraint exist on ("sourceCategoryId", "coreProductId"). When merging, if a record with a ("sourceCategoryId", new "coreProductId") exists, the record being merged should be deleted.
|coreProductCountryData     |YES        | FK to coreProducts exists as well, add NOT NULL constraint. UQ constraint exist on ("coreProductId", "countryId"). When merging, if a record with a ("countryId", new "coreProductId") exists, the record being merged should be deleted.


|coreRetailers              |YES        | there is no NOT NULL constraint on coreProductId and no FK to coreProducts. One record relates to non-existing coreProductId(36693). Other then this constraints can be added immediately,
                                          There is UQ on ("coreProductId", "retailerId", "productId"). However, this table should split in 2
                                            - one, keeping the name but with UQ ("coreProductId", "retailerId"), and
                                            - additional one,  a copy of the original, with UQ on ("coreProductId", "retailerId", "productId").
                                          Most of the tables relating to coreRetailers are relating on the coreProduct, not the sourceId(productId).


NOT included in the updates.
==========================================================================
|mappingSuggestions         |NO         | This table has less records than mappingLogs (when counting distinct coreProductId,suggestedProductId)
|coreProductsOverride       |YES        | A small table, only 3 records. Looks like coreRetailers.
|coreProductTaggings        |YES        | An empty table. New feature?
+---------------------------+-----------+
*/


/*  taxonomyProducts
    =============================================================


*/

SELECT "taxonomyId", "coreProductId", retailer, COUNT(*), STRING_AGG(DISTINCT "sourceId", ', ') AS "sourceIds"
FROM "taxonomyProducts"
GROUP BY 1, 2, 3
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

SELECT "coreProductId",
       COUNT(*),
       STRING_AGG(DISTINCT "taxonomyId", ', ') AS "taxonomyIds",
       STRING_AGG(DISTINCT "sourceId", ', ')   AS "sourceIds"
FROM "taxonomyProducts"
GROUP BY 1
ORDER BY COUNT(*);


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


    /*  another approach for updates/deletes    */
    /*  coreProductSourceCategories v.2 */

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


    /*
        /*  coreProductSourceCategories */
        WITH new AS (SELECT "sourceCategoryId"
                     FROM "coreProductSourceCategories"
                     WHERE "coreProductId" = "new_coreProductId")
        SELECT ARRAY_AGG("coreProductSourceCategories")
        INTO "deleted_coreProductSourceCategories"
        FROM "coreProductSourceCategories"
                 INNER JOIN new USING ("sourceCategoryId")
        WHERE "coreProductId" = "old_coreProductId";


        WITH new AS (SELECT "sourceCategoryId"
                     FROM "coreProductSourceCategories"
                     WHERE "coreProductId" = "new_coreProductId")
        SELECT ARRAY_AGG("id")
        INTO "updated_coreProductSourceCategories"
        FROM "coreProductSourceCategories"
                 LEFT OUTER JOIN new USING ("sourceCategoryId")
        WHERE "coreProductId" = "old_coreProductId"
          AND new."sourceCategoryId" IS NULL;


        WITH deleted AS (SELECT t.id FROM UNNEST("deleted_coreProductSourceCategories") AS t)
        DELETE
        FROM "coreProductSourceCategories" USING deleted
        WHERE "coreProductSourceCategories".id = deleted.id;

        UPDATE "coreProductSourceCategories"
        SET "coreProductId" = "new_coreProductId"
        WHERE id = ANY ("updated_coreProductSourceCategories");
    */
    /*  productGroupCoreProducts    */
    WITH new AS (SELECT "productGroupId"
                 FROM "productGroupCoreProducts"
                 WHERE "coreProductId" = "new_coreProductId")
    SELECT ARRAY_AGG("productGroupCoreProducts")
    INTO "deleted_productGroupCoreProducts"
    FROM "productGroupCoreProducts"
             INNER JOIN new USING ("productGroupId")
    WHERE "coreProductId" = "old_coreProductId";

    WITH new AS (SELECT "productGroupId"
                 FROM "productGroupCoreProducts"
                 WHERE "coreProductId" = "new_coreProductId")
    SELECT ARRAY_AGG("id")
    INTO "updated_productGroupCoreProducts"
    FROM "productGroupCoreProducts"
             LEFT OUTER JOIN new USING ("productGroupId")
    WHERE "coreProductId" = "old_coreProductId"
      AND new."productGroupId" IS NULL;


    WITH deleted AS (SELECT t.id FROM UNNEST("deleted_productGroupCoreProducts") AS t)
    DELETE
    FROM "productGroupCoreProducts" USING deleted
    WHERE "productGroupCoreProducts".id = deleted.id;

    UPDATE "productGroupCoreProducts"
    SET "coreProductId" = "new_coreProductId"
    WHERE id = ANY ("updated_productGroupCoreProducts");


    /*  coreProductCountryData  */
    WITH new AS (SELECT "countryId"
                 FROM "coreProductCountryData"
                 WHERE "coreProductId" = "new_coreProductId")
    SELECT ARRAY_AGG("coreProductCountryData")
    INTO "deleted_coreProductCountryData"
    FROM "coreProductCountryData"
             INNER JOIN new USING ("countryId")
    WHERE "coreProductId" = "old_coreProductId";

    WITH new AS (SELECT "countryId"
                 FROM "coreProductCountryData"
                 WHERE "coreProductId" = "new_coreProductId")
    SELECT ARRAY_AGG("id")
    INTO "updated_coreProductCountryData"
    FROM "coreProductCountryData"
             LEFT OUTER JOIN new USING ("countryId")
    WHERE "coreProductId" = "old_coreProductId"
      AND new."countryId" IS NULL;


    WITH deleted AS (SELECT t.id FROM UNNEST("deleted_coreProductCountryData") AS t)
    DELETE
    FROM "coreProductCountryData" USING deleted
    WHERE "coreProductCountryData".id = deleted.id;

    UPDATE "coreProductCountryData"
    SET "coreProductId" = "new_coreProductId"
    WHERE id = ANY ("updated_coreProductCountryData");

    /*  taxonomyProducts v.2 */
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

    /*  coreRetailers v.2 */
    WITH records_in_conflict AS (SELECT old.id
                                 FROM "coreRetailers" AS old
                                          INNER JOIN "coreRetailers" AS new
                                                     ON (old."coreProductId" = "old_coreProductId" AND
                                                         new."coreProductId" = "new_coreProductId" AND
                                                         old."retailerId" = new."retailerId" AND
                                                         old."productId" = new."productId")),
         deleted AS (
             DELETE
                 FROM "coreRetailers" USING records_in_conflict
                     WHERE "coreRetailers".id = records_in_conflict.id
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


    /*  DELETE core Product   */
    WITH deleted
             AS (
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
                                  "deleted_taxonomyProducts", "updated_coreRetailers", "deleted_coreRetailers")
    VALUES ("old_coreProductId", "new_coreProductId", "deleted_coreProduct", updated_products,
            "updated_coreProductBarcodes", "updated_coreProductSourceCategories",
            "deleted_coreProductSourceCategories", "updated_productGroupCoreProducts",
            "deleted_productGroupCoreProducts", "updated_coreProductCountryData",
            "deleted_coreProductCountryData", "updated_taxonomyProducts",
            "deleted_taxonomyProducts", "updated_coreRetailers", "deleted_coreRetailers")
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
    log staging.merge_log%ROWTYPE;
BEGIN

    SELECT *
    INTO log
    FROM staging.merge_log
    WHERE id = merge_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'merge id = % does not exist.', merge_id;
    END IF;

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


    /*  remove log entry. Maybe archive it?  */
    DELETE
    FROM staging.merge_log
    WHERE id = merge_id;

END
$$;

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



