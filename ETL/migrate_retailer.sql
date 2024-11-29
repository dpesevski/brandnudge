CREATE TABLE IF NOT EXISTS staging.migration_migrated_retailers
(
    "retailerId"      integer PRIMARY KEY,
    "migration_start" timestamp DEFAULT NOW(),
    "migration_end"   timestamp
);
ALTER TABLE public."productStatuses"
    DROP CONSTRAINT "productStatuses_pkey",
    ADD CONSTRAINT "productStatuses_pkey" UNIQUE (id) DEFERRABLE INITIALLY DEFERRED,
    ALTER CONSTRAINT "productstatuses_products_id_fk" DEFERRABLE INITIALLY DEFERRED;--[2024-11-29 18:16:42] completed in 2 m 36 s 385 ms

DROP INDEX productstatuses_productid_uindex;--[2024-11-29 18:16:42] completed in 188 ms

CREATE TABLE IF NOT EXISTS staging.product_status_history
(
    "retailerId"    integer NOT NULL,
    "coreProductId" integer NOT NULL,
    date            date    NOT NULL,
    "productId"     integer,
    status          text,
    CONSTRAINT product_status_history_pk
        PRIMARY KEY ("retailerId", "coreProductId", date) DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT product_status_history_productid_uindex UNIQUE ("productId") DEFERRABLE INITIALLY DEFERRED
);

CREATE OR REPLACE FUNCTION staging.migrate_retailer(id INTEGER) RETURNS void
    LANGUAGE plpgsql
AS
$$
BEGIN

    IF EXISTS (SELECT * FROM staging.migration_migrated_retailers WHERE id = migrate_retailer.id) THEN
        RAISE EXCEPTION 'retailer %s, already migrated', migrate_retailer.id;
    END IF;

    RAISE NOTICE '[%] T000: migrate_retailer %:   STARTED',CLOCK_TIMESTAMP(), migrate_retailer.id;
    INSERT INTO staging.migration_migrated_retailers ("retailerId")
    VALUES (migrate_retailer.id);

    DROP TABLE IF EXISTS staging.migration_product_status;
    CREATE TABLE staging.migration_product_status AS
    SELECT *
    FROM "productStatuses"
             INNER JOIN (SELECT products.id AS "productId", "retailerId", "coreProductId", "date"::date
                         FROM products
                         WHERE "retailerId" = migrate_retailer.id) AS products
                        USING ("productId");--[2024-11-28 15:22:52] 27,185,505 rows affected in 6 m 53 s 33 ms

    RAISE NOTICE '[%] T001: staging.migration_product_status:   CREATED',CLOCK_TIMESTAMP();

    CREATE UNIQUE INDEX migration_product_status_productid_uindex
        ON staging.migration_product_status ("productId");--[2024-11-28 15:23:25] completed in 16 s 282 ms

    CREATE INDEX migration_product_status_retailer_coreproduct_date_index
        ON staging.migration_product_status ("retailerId",
                                             "coreProductId",
                                             date);--[2024-11-28 15:23:49] completed in 23 s 775 ms
    CREATE INDEX migration_product_status_status_index
        ON staging.migration_product_status (status);
    --[2024-11-28 15:24:06] completed in 16 s 633 ms

    --[2024-11-28 16:36:27] completed in 4 m 29 s 139 ms

    /*  DELETE EXTRA De-listed records  */
    RAISE NOTICE '[%] T002: Cleaning of extra `De-listed` records :   STARTED',CLOCK_TIMESTAMP();

    CREATE TABLE IF NOT EXISTS staging.data_corr_status_extra_delisted_deleted AS TABLE "productStatuses"
        WITH NO DATA;
    WITH deleted AS (
        WITH product_status_prev AS (SELECT *,
                                            LAG("productId")
                                            OVER (PARTITION BY "retailerId","coreProductId" ORDER BY date, "productId" DESC) AS prev_product_id,
                                            LAG(status)
                                            OVER (PARTITION BY "retailerId","coreProductId" ORDER BY date, "productId" DESC) AS prev_status
                                     FROM staging.migration_product_status)
            DELETE
                FROM "productStatuses"
                    USING product_status_prev
                    WHERE "productStatuses"."productId" = product_status_prev."productId"
                        AND product_status_prev.status IN ('de-listed', 'De-listed')
                        AND product_status_prev.prev_status IN ('de-listed', 'De-listed')
                    RETURNING "productStatuses".*)
    INSERT
    INTO staging.data_corr_status_extra_delisted_deleted
    SELECT *
    FROM deleted;--[2024-11-28 17:34:43] 94,805 rows affected in 2 m 11 s 12 ms

    RAISE NOTICE '[%] T003: INSERT INTO staging.data_corr_status_extra_delisted_deleted :   COMPLETED',CLOCK_TIMESTAMP();

    CREATE TABLE IF NOT EXISTS staging.data_corr_status_deleted_aggregatedProducts AS TABLE "aggregatedProducts"
        WITH NO DATA;
    WITH deleted AS (
        DELETE
            FROM "aggregatedProducts"
                USING staging.data_corr_status_extra_delisted_deleted
                WHERE "aggregatedProducts"."productId" = data_corr_status_extra_delisted_deleted."productId"
                RETURNING "aggregatedProducts".*)
    INSERT
    INTO staging.data_corr_status_deleted_aggregatedProducts
    SELECT *
    FROM deleted;

    CREATE TABLE IF NOT EXISTS staging.data_corr_status_deleted_productsData AS TABLE "productsData"
        WITH NO DATA;
    WITH deleted AS (
        DELETE
            FROM "productsData"
                USING staging.data_corr_status_extra_delisted_deleted
                WHERE "productsData"."productId" = data_corr_status_extra_delisted_deleted."productId"
                RETURNING "productsData".*)
    INSERT
    INTO staging.data_corr_status_deleted_productsData
    SELECT *
    FROM deleted;

    RAISE NOTICE '[%] T004: INSERT INTO staging.data_corr_status_deleted_productsData :   COMPLETED',CLOCK_TIMESTAMP();

    CREATE TABLE IF NOT EXISTS staging.data_corr_status_deleted_promotions AS TABLE "promotions" WITH NO DATA;
    WITH deleted AS (
        DELETE
            FROM "promotions"
                USING staging.data_corr_status_extra_delisted_deleted
                WHERE "promotions"."productId" = data_corr_status_extra_delisted_deleted."productId"
                RETURNING "promotions".*)
    INSERT
    INTO staging.data_corr_status_deleted_promotions
    SELECT *
    FROM deleted;

    CREATE TABLE IF NOT EXISTS staging.data_corr_status_deleted_products AS TABLE products WITH NO DATA;
    WITH deleted AS (
        DELETE
            FROM products
                USING staging.data_corr_status_extra_delisted_deleted
                WHERE products.id = data_corr_status_extra_delisted_deleted."productId"
                RETURNING products.*)
    INSERT
    INTO staging.data_corr_status_deleted_products
    SELECT *
    FROM deleted;
    --[2024-11-28 17:59:01] 94,805 rows affected in 16 s 218 ms

    RAISE NOTICE '[%] T005: INSERT INTO staging.data_corr_status_deleted_products :   COMPLETED',CLOCK_TIMESTAMP();

    DELETE
    FROM staging.migration_product_status
        USING staging.data_corr_status_extra_delisted_deleted
    WHERE migration_product_status."productId" = data_corr_status_extra_delisted_deleted."productId";

    RAISE NOTICE '[%] T006: Cleaning of extra `De-listed` records :   COMPLETED',CLOCK_TIMESTAMP();

    /*  DELETE EXTRA De-listed records:  END */


    /*
    brandnudge-dev.public> SELECT staging.migrate_retailer(1)
    [2024-11-28 18:38:35] [42P07] relation "products_retailerid_index" already exists, skipping
    products_retailerId_index created
    [2024-11-28 18:38:35] [42P07] relation "migration_migrated_retailers" already exists, skipping
    staging.migration_product_status created
    Cleaning of extra `De-listed` records started
    [2024-11-28 18:42:51] [42P07] relation "data_corr_status_extra_delisted_deleted" already exists, skipping
    staging.data_corr_status_extra_delisted_deleted updated
    [2024-11-28 18:44:28] [42P07] relation "data_corr_status_deleted_aggregatedproducts" already exists, skipping
    [2024-11-28 18:44:33] [42P07] relation "data_corr_status_deleted_productsdata" already exists, skipping
    staging.data_corr_status_deleted_productsData updated
    [2024-11-28 18:44:44] [42P07] relation "data_corr_status_deleted_promotions" already exists, skipping
    [2024-11-28 18:44:45] [42P07] relation "data_corr_status_deleted_products" already exists, skipping
    staging.data_corr_status_deleted_products updated
    Cleaning of extra `De-listed` records completed
    [2024-11-28 18:45:04] 1 row retrieved starting from 1 in 6 m 29 s 421 ms (execution: 6 m 28 s 817 ms, fetching: 604 ms)
    */

    DROP TABLE IF EXISTS staging.migstatus_products_filtered;
    CREATE TABLE staging.migstatus_products_filtered AS
    WITH products AS (SELECT "retailerId",
                             "coreProductId",
                             date                                                                             AS load_date,
                             "productId",
                             ROW_NUMBER()
                             OVER (PARTITION BY "retailerId","coreProductId", date ORDER BY "productId" DESC) AS rownum
                      FROM staging.migration_product_status
                      WHERE status NOT IN ('de-listed', 'De-listed'))
    SELECT "retailerId",
           "coreProductId",
           load_date,
           "productId"
    FROM products
    WHERE rownum = 1
    ORDER BY "retailerId", "coreProductId", load_date; --[2024-11-28 20:17:47] 26,358,160 rows affected in 2 m 5 s 915 ms

    RAISE NOTICE '[%] T007: staging.migstatus_products_filtered :   CREATED',CLOCK_TIMESTAMP();

    CREATE INDEX IF NOT EXISTS migstatus_products_filtered_retailerId_coreProductId_date_index
        ON staging.migstatus_products_filtered ("retailerId", "coreProductId", load_date); --[2024-11-28 20:23:00] completed in 17 s 538 ms
    RAISE NOTICE '[%] T008: migstatus_products_filtered_retailerId_coreProductId_date_index :   CREATED',CLOCK_TIMESTAMP();

    CREATE TABLE IF NOT EXISTS staging.product_status_history
    (
        "retailerId"    integer NOT NULL,
        "coreProductId" integer NOT NULL,
        date            date    NOT NULL,
        "productId"     integer,
        status          text,
        CONSTRAINT product_status_history_pk
            PRIMARY KEY ("retailerId", "coreProductId", date) DEFERRABLE INITIALLY DEFERRED,
        CONSTRAINT product_status_history_productid_uindex UNIQUE ("productId") DEFERRABLE INITIALLY DEFERRED
    );


    --CREATE UNIQUE INDEX IF NOT EXISTS product_status_history_productid_uindex ON staging.product_status_history ("productId");

    DELETE
    FROM staging.product_status_history
    WHERE "retailerId" = migrate_retailer.id; --27,156,189 rows affected in 1 m 25 s 103 ms
    RAISE NOTICE '[%] T009: DELETE from staging.product_status_history :   COMPLETED',CLOCK_TIMESTAMP();

    WITH retailer_product_load AS (SELECT "retailerId",
                                          "coreProductId",
                                          load_date,
                                          "productId",
                                          LAG(load_date)
                                          OVER (PARTITION BY "retailerId","coreProductId" ORDER BY load_date) AS prev_load_date
                                   FROM staging.migstatus_products_filtered),
         ins_data AS (SELECT "retailerId",
                             "coreProductId",
                             load_date AS date,
                             "productId",
                             CASE
                                 WHEN prev_load_date IS NULL THEN 'Newly'
                                 WHEN prev_load_date = load_date - '1 day'::interval
                                     THEN 'Listed'
                                 ELSE 'Re-listed'
                                 END   AS status
                      FROM retailer_product_load

                      UNION ALL

                      SELECT "retailerId",
                             "coreProductId",
                             (prev_load_date + '1 day'::interval)::date AS date,
                             NULL                                       AS "productId",
                             'De-listed'                                AS status
                      FROM retailer_product_load
                      WHERE prev_load_date < load_date - '1 day'::interval)
    INSERT
    INTO staging.product_status_history ("retailerId", "coreProductId", date, "productId", status)
    SELECT "retailerId", "coreProductId", date, "productId", status
    FROM ins_data;
    -- CREATE TABLE [2024-11-28 20:25:49] 27,124,321 rows affected in 1 m 47 s 404 ms
    -- INSERT INTO  [2024-11-28 20:58:28] 27,124,321 rows affected in 7 m 25 s 702 ms

    RAISE NOTICE '[%] T010: INSERT INTO staging.product_status_history 1ST PART :   COMPLETED',CLOCK_TIMESTAMP();

    WITH last_product_load AS (SELECT "retailerId", "coreProductId", MAX(load_date) AS load_date
                               FROM staging.migstatus_products_filtered
                               GROUP BY "retailerId", "coreProductId"),

         last_retailer_load AS (SELECT "retailerId", MAX(load_date) AS last_load_date
                                FROM staging.migstatus_products_filtered
                                GROUP BY "retailerId")
    INSERT
    INTO staging.product_status_history("retailerId", "coreProductId", date, "productId", status)
    SELECT "retailerId",
           "coreProductId",
           (load_date + '1 day'::interval)::date AS date,
           NULL                                  AS "productId",
           'De-listed'                           AS status
    FROM last_product_load
             INNER JOIN last_retailer_load USING ("retailerId")
    WHERE load_date < last_load_date; -- [2024-11-28 20:59:50] 41,128 rows affected in 9 s 328 ms

    RAISE NOTICE '[%] T011: INSERT INTO staging.product_status_history 2ND PART :   COMPLETED',CLOCK_TIMESTAMP();

    DROP TABLE IF EXISTS staging."migstatus_productStatuses_additional";

    CREATE TABLE staging."migstatus_productStatuses_additional" AS
    SELECT "productStatuses".*
    FROM staging.migration_product_status AS "productStatuses"
             LEFT OUTER JOIN staging.product_status_history USING ("productId")
    WHERE product_status_history."productId" IS NULL; --[2024-11-28 21:06:46] 703,455 rows affected in 33 s 789 ms


    RAISE NOTICE '[%] T012: migstatus_productStatuses_additional :   CREATED',CLOCK_TIMESTAMP();


    CREATE UNIQUE INDEX migstatus_productStatuses_additional_productid_uindex
        ON staging."migstatus_productStatuses_additional" ("productId");

    CREATE INDEX migstatus_productStatuses_additional_productid_addindex
        ON staging."migstatus_productStatuses_additional" ("retailerId",
                                                           "coreProductId",
                                                           date);
    CREATE INDEX migstatus_productStatuses_additional_productid_statusindex
        ON staging."migstatus_productStatuses_additional" (status);
    RAISE NOTICE '[%] T013: migstatus_productStatuses_additional INDEXES :   CREATED',CLOCK_TIMESTAMP();

    WITH delisted AS (SELECT "retailerId",
                             "coreProductId",
                             date,
                             "productId",
                             ROW_NUMBER() OVER (PARTITION BY "retailerId",
                                 "coreProductId",
                                 date ORDER BY "productId" DESC) AS rownum
                      FROM staging."migstatus_productStatuses_additional"
                      WHERE status IN ('de-listed', 'De-listed'))
    INSERT
    INTO staging.product_status_history("retailerId", "coreProductId", date, "productId", status)
    SELECT "retailerId",
           "coreProductId",
           date,
           "productId",
           'De-listed' AS status
    FROM delisted
    WHERE rownum = 1
    ON CONFLICT ("retailerId", "coreProductId", date)
        DO UPDATE
        SET "productId"=excluded."productId"
    WHERE product_status_history."productId" IS NULL;
    -- [2024-11-28 21:12:02] 703,224 rows affected in 30 s 11 ms

    RAISE NOTICE '[%] T014: INSERT INTO staging.product_status_history 3RD PART (ADDITIONAL) :   COMPLETED',CLOCK_TIMESTAMP();

/*
after the update
+---------+--------+---------+
|status   |delisted|count    |
+---------+--------+---------+
|De-listed|false   |  2357894| Less than half of the "De-listed" events have been recorded in productStatuses
|De-listed|true    |  3310580| TO DO:   these need to be inserted in products first
|Listed   |false   |266615171|
|Newly    |false   |  1086394|
|Re-listed|false   |  4883591|
+---------+--------+---------+
*/
    DROP TABLE IF EXISTS staging.migstatus_ins_products;
    CREATE TABLE staging.migstatus_ins_products AS
    WITH delisted AS (SELECT "retailerId",
                             "coreProductId",
                             "date"                                                                  AS delisted_date,
                             ROW_NUMBER() OVER (PARTITION BY "retailerId", "coreProductId", "date" ) AS rownum
                      FROM staging.product_status_history
                      WHERE "productId" IS NULL),
         last_load_product AS (SELECT delisted."retailerId",
                                      delisted."coreProductId",
                                      delisted.delisted_date,
                                      MAX(product.load_date) AS load_date
                               FROM delisted
                                        INNER JOIN staging.migstatus_products_filtered AS product
                                                   ON (product."retailerId" = delisted."retailerId" AND
                                                       product."coreProductId" = delisted."coreProductId" AND
                                                       product.load_date < delisted.delisted_date)
                               GROUP BY delisted."retailerId",
                                        delisted."coreProductId",
                                        delisted.delisted_date),
         ins_prod_selection AS (SELECT "productId" AS id,
                                       delisted_date,
                                       dates.id    AS delisted_date_id
                                FROM staging.migstatus_products_filtered
                                         INNER JOIN last_load_product USING ("retailerId", "coreProductId", load_date)
                                         LEFT OUTER JOIN dates ON (dates."date" = delisted_date))
    SELECT NEXTVAL('products_id_seq'::regclass) AS id,
           "sourceType",
           ean,
           promotions,
           "promotionDescription",
           features,
           delisted_date                        AS date,
           "sourceId",
           "productBrand",
           "productTitle",
           "productImage",
           "secondaryImages",
           "productDescription",
           "productInfo",
           "promotedPrice",
           "productInStock",
           "productInListing",
           "reviewsCount",
           "reviewsStars",
           "eposId",
           multibuy,
           "coreProductId",
           "retailerId",
--                        CURRENT_TIMESTAMP AS "createdAt",
--                        CURRENT_TIMESTAMP AS "updatedAt",
           '2000-01-01'::timestamptz            AS "createdAt",
           '2000-01-01'::timestamptz            AS "updatedAt",
           "imageId",
           size,
           "pricePerWeight",
           href,
           nutritional,
           "basePrice",
           "shelfPrice",
           "productTitleDetail",
           "sizeUnit",
           delisted_date_id                     AS "dateId",
           marketplace,
           "marketplaceData",
           "priceMatchDescription",
           "priceMatch",
           "priceLock",
           "isNpd",
           NULL::integer                        AS load_id
    FROM products
             INNER JOIN ins_prod_selection USING (id);
-- [2024-11-28 21:13:47] 104,440 rows affected in 14 s 760 ms
    RAISE NOTICE '[%] T015: staging.migstatus_ins_products :   CREATED',CLOCK_TIMESTAMP();

    INSERT
    INTO products
    SELECT*
    FROM staging.migstatus_ins_products;
--3,310,580 rows affected in 31 m 23 s 196 ms
    RAISE NOTICE '[%] T016: INSERT INTO PRODUCTS :   COMPLETED',CLOCK_TIMESTAMP();


    UPDATE staging.product_status_history AS history
    SET "productId"=ins_products.id
    FROM staging.migstatus_ins_products AS ins_products
    WHERE history."retailerId" = ins_products."retailerId"
      AND history."coreProductId" = ins_products."coreProductId"
      AND history.date = ins_products.date;
-- 2,752,620 rows affected in 9 m 4 s 600 ms
    RAISE NOTICE '[%] T017: UPDATED staging.product_status_history :   COMPLETED',CLOCK_TIMESTAMP();

    CREATE TABLE IF NOT EXISTS staging.data_corr_ret_mig_prod_status_bck AS TABLE public."productStatuses"
        WITH NO DATA;

    WITH deleted AS (
        DELETE FROM "productStatuses"
            USING staging.migration_product_status WHERE
                "productStatuses"."productId" = migration_product_status."productId"
                    AND migration_product_status."retailerId" = migrate_retailer.id
            RETURNING "productStatuses".*)
    INSERT
    INTO staging.data_corr_ret_mig_prod_status_bck
    SELECT *
    FROM deleted;
    RAISE NOTICE '[%] T018: DELETE FROM "productStatuses" :   COMPLETED',CLOCK_TIMESTAMP();


    INSERT INTO "productStatuses"
    SELECT COALESCE("productStatuses".id, NEXTVAL('"productStatuses_id_seq"'::regclass)) AS id,
           "productId",
           product_status_history.status,
           "productStatuses".screenshot,
           COALESCE("productStatuses"."createdAt", CURRENT_TIMESTAMP)                    AS "createdAt",
           COALESCE("productStatuses"."updatedAt", CURRENT_TIMESTAMP)                    AS "updatedAt",
           "productStatuses".load_id
    FROM staging.product_status_history
             LEFT OUTER JOIN public."productStatuses" USING ("productId");
    --278,253,630 rows affected in 22 m 39 s 456 ms
    --288,009,947 rows affected in 22 m 54 s 758 ms
    RAISE NOTICE '[%] T019: INSERT INTO "productStatuses" :   COMPLETED',CLOCK_TIMESTAMP();

    UPDATE staging.migration_migrated_retailers
    SET migration_end=CLOCK_TIMESTAMP()
    WHERE "retailerId" = migrate_retailer.id;
END
$$;

SET work_mem = '4GB';
SET max_parallel_workers_per_gather = 4;
SHOW WORK_MEM;

/*  TODO:   REMOVE BEFORE COMMITING TO REPO */
--TRUNCATE TABLE staging.migration_migrated_retailers;

SELECT staging.migrate_retailer(1); -- 703.224 De-listed

CREATE UNIQUE INDEX productstatuses_productid_uindex
    ON public."productStatuses" ("productId");

VACUUM FULL "productStatuses";


/*
brandnudge-dev.public> SELECT staging.migrate_retailer(1)
[2024-11-29 15:13:21.31912+00] T000: migrate_retailer 1:   STARTED
table "migration_product_status" does not exist, skipping
[2024-11-29 15:17:59.112371+00] T001: staging.migration_product_status:   CREATED
[2024-11-29 15:18:56.011565+00] T002: Cleaning of extra `De-listed` records :   STARTED
[2024-11-29 15:20:46.481353+00] T003: INSERT INTO staging.data_corr_status_extra_delisted_deleted :   COMPLETED
[2024-11-29 15:21:07.165019+00] T004: INSERT INTO staging.data_corr_status_deleted_productsData :   COMPLETED
[2024-11-29 15:21:46.332277+00] T005: INSERT INTO staging.data_corr_status_deleted_products :   COMPLETED
[2024-11-29 15:21:47.240964+00] T006: Cleaning of extra `De-listed` records :   COMPLETED
table "migstatus_products_filtered" does not exist, skipping
[2024-11-29 15:23:59.958801+00] T007: staging.migstatus_products_filtered :   CREATED
[2024-11-29 15:24:18.043464+00] T008: migstatus_products_filtered_retailerId_coreProductId_date_index :   CREATED
[2024-11-29 15:24:18.073858+00] T009: DELETE from staging.product_status_history :   COMPLETED
[2024-11-29 15:30:19.172783+00] T010: INSERT INTO staging.product_status_history 1ST PART :   COMPLETED
[2024-11-29 15:30:29.025444+00] T011: INSERT INTO staging.product_status_history 2ND PART :   COMPLETED
table "migstatus_productStatuses_additional" does not exist, skipping
[2024-11-29 15:30:35.885308+00] T012: migstatus_productStatuses_additional :   CREATED
[2024-11-29 15:30:37.014491+00] T013: migstatus_productStatuses_additional INDEXES :   CREATED
[2024-11-29 15:30:54.991972+00] T014: INSERT INTO staging.product_status_history 3RD PART (ADDITIONAL) :   COMPLETED
table "migstatus_ins_products" does not exist, skipping
[2024-11-29 15:31:22.192103+00] T015: staging.migstatus_ins_products :   CREATED
[2024-11-29 15:33:09.049099+00] T016: INSERT INTO PRODUCTS :   COMPLETED
[2024-11-29 15:33:10.272672+00] T017: UPDATED staging.product_status_history :   COMPLETED
[2024-11-29 15:50:41.276239+00] T018: DELETE FROM "productStatuses" :   COMPLETED
*/