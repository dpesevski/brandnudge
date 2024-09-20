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

SELECT *
FROM "coreProducts"
WHERE "productGroupId" IS NOT NULL
ORDER BY "createdAt" DESC;


/*  pre-script, add missing constraints */
ALTER TABLE "coreProductBarcodes"
    ALTER COLUMN "coreProductId" SET NOT NULL;

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

    "updated_products"                    integer[],


    "updated_taxonomyProducts"            integer[],
    "updated_productGroupCoreProducts"    integer[],

    "updated_coreProductBarcodes"         integer[],

    "updated_coreProductSourceCategories" integer[],
    "deleted_coreProductSourceCategories" "coreProductSourceCategories"[],

    "updated_coreRetailers"               integer[],

    "deleted_coreProduct"                 "coreProducts",

    "createAt"                            timestamptz DEFAULT CURRENT_TIMESTAMP
);


DROP FUNCTION IF EXISTS staging.merge(integer, integer);
CREATE OR REPLACE FUNCTION staging.merge("old_coreProductId" integer, "new_coreProductId" integer) RETURNS integer
    LANGUAGE plpgsql
AS
$$
DECLARE
    _merge_id                              integer;
    "_deleted_coreProduct"                 "coreProducts";
    "_updated_products"                    integer[];
    "_updated_coreProductBarcodes"         integer[];
    "_updated_coreProductSourceCategories" integer[];
    "_deleted_coreProductSourceCategories" "coreProductSourceCategories"[];
BEGIN

    SELECT *
    INTO "_deleted_coreProduct"
    FROM "coreProducts"
    WHERE id = "old_coreProductId";

    IF NOT FOUND THEN
        RAISE NOTICE 'old coreProductId = % not found.', "old_coreProductId";
        RETURN -1;
    END IF;

    IF NOT EXISTS (SELECT *
                   FROM "coreProducts"
                   WHERE id = "new_coreProductId") THEN
        RAISE EXCEPTION 'new coreProductId = % not found.', "new_coreProductId";
    END IF;

    INSERT INTO staging.merge_log("old_coreProductId", "new_coreProductId", "deleted_coreProduct")
    VALUES ("old_coreProductId", "new_coreProductId", "_deleted_coreProduct")
    RETURNING id INTO _merge_id;

    WITH upd AS (
        UPDATE products
            SET "coreProductId" = "new_coreProductId"
            WHERE "coreProductId" = "old_coreProductId"
            RETURNING id)
    SELECT ARRAY_AGG(id)
    INTO "_updated_products"
    FROM upd;


    WITH upd AS (
        UPDATE "coreProductBarcodes"
            SET "coreProductId" = "new_coreProductId"
            WHERE "coreProductId" = "old_coreProductId"
            RETURNING id)
    SELECT ARRAY_AGG(id)
    INTO "_updated_coreProductBarcodes"
    FROM upd;


    WITH new AS (SELECT "sourceCategoryId"
                 FROM "coreProductSourceCategories"
                 WHERE "coreProductId" = "new_coreProductId")
    SELECT ARRAY_AGG("coreProductSourceCategories")
    INTO "_deleted_coreProductSourceCategories"
    FROM "coreProductSourceCategories"
             INNER JOIN new USING ("sourceCategoryId")
    WHERE "coreProductId" = "old_coreProductId";


    WITH new AS (SELECT "sourceCategoryId"
                 FROM "coreProductSourceCategories"
                 WHERE "coreProductId" = "new_coreProductId")
    SELECT ARRAY_AGG("id")
    INTO "_updated_coreProductSourceCategories"
    FROM "coreProductSourceCategories"
             LEFT OUTER JOIN new USING ("sourceCategoryId")
    WHERE "coreProductId" = "old_coreProductId"
      AND new."sourceCategoryId" IS NULL;


    UPDATE staging.merge_log
    SET "deleted_coreProduct"="_deleted_coreProduct",

        "updated_products"="_updated_products",

        "updated_coreProductBarcodes"="_updated_coreProductBarcodes",

        "deleted_coreProductSourceCategories"="_deleted_coreProductSourceCategories",
        "updated_coreProductSourceCategories"="_updated_coreProductSourceCategories"
    WHERE id = _merge_id;


    /*  DELETE core Product
    DELETE
    FROM "coreProducts"
    WHERE id = "old_coreProductId";
    */

    RETURN _merge_id;
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

    INSERT INTO "coreProducts"
    SELECT (log."deleted_coreProduct").*
    ON CONFLICT DO NOTHING; -- TO DO: REMOVE WHEN ALL TABLES ARE IMPLEMENTED IN THE MERGE FUNCTION, WITH NO RELATED RECORDS LEFT SO COREPRODUCT RECORD CAN BE DELETED.

    UPDATE products
    SET "coreProductId" = (log."old_coreProductId")
    WHERE id = ANY (log."updated_products");

    UPDATE "coreProductBarcodes"
    SET "coreProductId" = (log."old_coreProductId")
    WHERE id = ANY (log."updated_coreProductBarcodes");

    UPDATE "coreProductSourceCategories"
    SET "coreProductId" = (log."old_coreProductId")
    WHERE id = ANY (log."updated_coreProductSourceCategories");

    WITH deleted_records AS (SELECT t.*
                             FROM UNNEST(log."deleted_coreProductSourceCategories") AS t)
    INSERT
    INTO "coreProductSourceCategories"
    SELECT *
    FROM deleted_records;

    DELETE
    FROM staging.merge_log
    WHERE id = merge_id;

END
$$;

SELECT staging.merge(1308689, 601245);

SELECT *
FROM staging.merge_log;

SELECT "coreProductId"
FROM products
WHERE id = 267666566;

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
WHERE id = 1308689;

SELECT staging.reverse_merge(1);


WITH affected_record AS (SELECT *
                         FROM staging.merge_log
                         WHERE id = 1),
     updated_records AS (SELECT t.id, "old_coreProductId"
                         FROM affected_record
                                  CROSS JOIN LATERAL UNNEST("updated_products") AS t(id))
UPDATE products
SET "coreProductId"="old_coreProductId"
FROM updated_records
WHERE products.id = updated_records.id;