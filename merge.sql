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
FROM information_schema.columns
WHERE table_schema = 'public'
  AND LOWER(column_name) LIKE '%prod%gr%';


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
    _merge_id              integer;
    "affected_coreProduct" "coreProducts"%ROWTYPE;
BEGIN

    SELECT *
    INTO "affected_coreProduct"
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
    VALUES ("old_coreProductId", "new_coreProductId", "affected_coreProduct")
    RETURNING id INTO _merge_id;

    CREATE TEMPORARY TABLE merge_updated_products ON COMMIT DROP AS
    WITH upd AS (
        UPDATE products
            SET "coreProductId" = "new_coreProductId"
            WHERE "coreProductId" = "old_coreProductId"
            RETURNING id)
    SELECT ARRAY_AGG(id) AS updated_ids
    FROM upd;

    UPDATE staging.merge_log
    SET updated_products=merge_updated_products.updated_ids
    FROM merge_updated_products
    WHERE id = _merge_id;


    /*  DELETE core Product
    DELETE
    FROM "coreProducts"
    WHERE id = "old_coreProductId";
    */

    DROP TABLE merge_updated_products;

    RETURN _merge_id;
END
$$;

DROP FUNCTION IF EXISTS staging.reverse_merge(integer);
CREATE OR REPLACE FUNCTION staging.reverse_merge(merge_id integer) RETURNS void
    LANGUAGE plpgsql
AS
$$
DECLARE
    affected_record staging.merge_log%ROWTYPE;
BEGIN

    SELECT *
    INTO affected_record
    FROM staging.merge_log
    WHERE id = merge_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'merge id = % does not exist.', merge_id;
    END IF;

    INSERT INTO "coreProducts"
    SELECT (affected_record."deleted_coreProduct").*;

    CREATE TEMPORARY TABLE merge_reversed_products ON COMMIT DROP AS
    WITH upd AS (
        UPDATE products
            SET "coreProductId" = affected_record."old_coreProductId"
            WHERE id = ANY (affected_record.updated_products)
            RETURNING id)
    SELECT *
    FROM upd;

    DELETE
    FROM staging.merge_log
    WHERE id = merge_id;

    DROP TABLE merge_reversed_products;

END
$$;

SELECT staging.merge(1308689, 601245);

SELECT *
FROM staging.merge_log;

SELECT "coreProductId"
FROM products
WHERE id = 267666566;

WITH affected_record AS (SELECT *
                         FROM staging.merge_log
                         WHERE id = 6)
SELECT ("deleted_coreProduct").*
FROM affected_record;


SELECT *
FROM "coreProducts"
WHERE id = 1308689;

SELECT staging.reverse_merge(6);



