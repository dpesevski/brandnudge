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
FROM "coreProductCountryData";


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

    "updated_products"                    integer[],


    "updated_taxonomyProducts"            integer[],

    "updated_coreProductBarcodes"         integer[],

    "updated_coreProductSourceCategories" integer[],
    "deleted_coreProductSourceCategories" "coreProductSourceCategories"[],

    "updated_productGroupCoreProducts"    integer[],
    "deleted_productGroupCoreProducts"    "productGroupCoreProducts"[],

    "updated_coreProductCountryData"      integer[],
    "deleted_coreProductCountryData"      "coreProductCountryData"[],

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
    "_updated_productGroupCoreProducts"    integer[];
    "_deleted_productGroupCoreProducts"    "productGroupCoreProducts"[];
    "_updated_coreProductCountryData"      integer[];
    "_deleted_coreProductCountryData"      "coreProductCountryData"[];

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

    /*  coreProductSourceCategories */
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


    WITH deleted AS (SELECT t.id FROM UNNEST("_deleted_coreProductSourceCategories") AS t)
    DELETE
    FROM "coreProductSourceCategories" USING deleted
    WHERE "coreProductSourceCategories".id = deleted.id;

    UPDATE "coreProductSourceCategories"
    SET "coreProductId" = "new_coreProductId"
    WHERE id = ANY ("_updated_coreProductSourceCategories");

    /*  productGroupCoreProducts    */
    WITH new AS (SELECT "productGroupId"
                 FROM "productGroupCoreProducts"
                 WHERE "coreProductId" = "new_coreProductId")
    SELECT ARRAY_AGG("productGroupCoreProducts")
    INTO "_deleted_productGroupCoreProducts"
    FROM "productGroupCoreProducts"
             INNER JOIN new USING ("productGroupId")
    WHERE "coreProductId" = "old_coreProductId";

    WITH new AS (SELECT "productGroupId"
                 FROM "productGroupCoreProducts"
                 WHERE "coreProductId" = "new_coreProductId")
    SELECT ARRAY_AGG("id")
    INTO "_updated_productGroupCoreProducts"
    FROM "productGroupCoreProducts"
             LEFT OUTER JOIN new USING ("productGroupId")
    WHERE "coreProductId" = "old_coreProductId"
      AND new."productGroupId" IS NULL;


    WITH deleted AS (SELECT t.id FROM UNNEST("_deleted_productGroupCoreProducts") AS t)
    DELETE
    FROM "productGroupCoreProducts" USING deleted
    WHERE "productGroupCoreProducts".id = deleted.id;

    UPDATE "productGroupCoreProducts"
    SET "coreProductId" = "new_coreProductId"
    WHERE id = ANY ("_updated_productGroupCoreProducts");


    /*  coreProductCountryData  */
    WITH new AS (SELECT "countryId"
                 FROM "coreProductCountryData"
                 WHERE "coreProductId" = "new_coreProductId")
    SELECT ARRAY_AGG("coreProductCountryData")
    INTO "_deleted_coreProductCountryData"
    FROM "coreProductCountryData"
             INNER JOIN new USING ("countryId")
    WHERE "coreProductId" = "old_coreProductId";

    WITH new AS (SELECT "countryId"
                 FROM "coreProductCountryData"
                 WHERE "coreProductId" = "new_coreProductId")
    SELECT ARRAY_AGG("id")
    INTO "_updated_coreProductCountryData"
    FROM "coreProductCountryData"
             LEFT OUTER JOIN new USING ("countryId")
    WHERE "coreProductId" = "old_coreProductId"
      AND new."countryId" IS NULL;


    WITH deleted AS (SELECT t.id FROM UNNEST("_deleted_coreProductCountryData") AS t)
    DELETE
    FROM "coreProductCountryData" USING deleted
    WHERE "coreProductCountryData".id = deleted.id;

    UPDATE "coreProductCountryData"
    SET "coreProductId" = "new_coreProductId"
    WHERE id = ANY ("_updated_coreProductCountryData");


    /*  merge log update    */
    UPDATE staging.merge_log
    SET "deleted_coreProduct"="_deleted_coreProduct",

        "updated_products"="_updated_products",

        "updated_coreProductBarcodes"="_updated_coreProductBarcodes",

        "deleted_coreProductSourceCategories"="_deleted_coreProductSourceCategories",
        "updated_coreProductSourceCategories"="_updated_coreProductSourceCategories",

        "deleted_productGroupCoreProducts"="_deleted_productGroupCoreProducts",
        "updated_productGroupCoreProducts"="_updated_productGroupCoreProducts",

        "deleted_coreProductCountryData"="_deleted_coreProductCountryData",
        "updated_coreProductCountryData"="_updated_coreProductCountryData"

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

    /*  coreProducts */
    INSERT INTO "coreProducts"
    SELECT (log."deleted_coreProduct").*
    ON CONFLICT DO NOTHING;
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

    /*  remove log entry. Maybe archive it?  */
    DELETE
    FROM staging.merge_log
    WHERE id = merge_id;

END
$$;

SELECT staging.merge(1308689, 601245);

SELECT *
FROM staging.merge_log;

SELECT *
FROM "coreProductCountryData"
WHERE id = 1127868;


SELECT "coreProductId"
FROM "coreProductSourceCategories"
WHERE id = 6377183;

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

SELECT staging.reverse_merge(2);



