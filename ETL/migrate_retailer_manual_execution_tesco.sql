SET work_mem = '4GB';
SET max_parallel_workers_per_gather = 4;
SHOW WORK_MEM;
SHOW max_parallel_workers_per_gather;

/*  create tables for backup of data related to extra De-listed records   */
CREATE TABLE IF NOT EXISTS staging.data_corr_status_extra_delisted_deleted AS TABLE "productStatuses"
    WITH NO DATA;
CREATE TABLE IF NOT EXISTS staging.data_corr_status_deleted_aggregatedProducts AS TABLE "aggregatedProducts"
    WITH NO DATA;
CREATE TABLE IF NOT EXISTS staging.data_corr_status_deleted_productsData AS TABLE "productsData"
    WITH NO DATA;
CREATE TABLE IF NOT EXISTS staging.data_corr_status_deleted_promotions AS TABLE "promotions" WITH NO DATA;
CREATE TABLE IF NOT EXISTS staging.data_corr_status_deleted_products AS TABLE products WITH NO DATA;
CREATE TABLE IF NOT EXISTS staging.data_corr_ret_mig_prod_status_bck AS TABLE public."productStatuses"
    WITH NO DATA;

/*  migrate_retailer    */
--DROP TABLE IF EXISTS staging.product_status_history;
CREATE TABLE IF NOT EXISTS staging.product_status_history
(
    "retailerId"    integer NOT NULL,
    "coreProductId" integer NOT NULL,
    date            date    NOT NULL,
    "productId"     integer,
    status          text,
    CONSTRAINT product_status_history_pk
        PRIMARY KEY ("retailerId", "coreProductId", date),--DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT product_status_history_productid_uindex UNIQUE ("productId")-- DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE IF NOT EXISTS staging.migration_migrated_retailers
(
    "retailerId"      integer PRIMARY KEY,
    "migration_start" timestamp DEFAULT NOW(),
    "migration_end"   timestamp
);


--RAISE NOTICE '[%] T000: migrate_retailer %:   STARTED',CLOCK_TIMESTAMP(), 1;
INSERT INTO staging.migration_migrated_retailers ("retailerId")
SELECT id
FROM retailers
WHERE id NOT IN (1, 2, 3, 8, 10, 13);

/*
NON-PP RETAILERS
+--+------------+
|id|name        |
+--+------------+
|2 |asda        |
|3 |sainsburys  |
|8 |ocado       |
|10|waitrose    |
|13|amazon_fresh|
+--+------------+
*/

SELECT *
FROM staging.migration_migrated_retailers;
/*
retailerId IN
  (4, 9, 11, 48, 81, 114, 115, 159, 345, 378, 411, 444, 477, 510, 543, 576, 609, 642, 675, 708, 741, 774, 775, 807,
   840, 873, 906, 907, 908, 909, 910, 911, 912, 913, 914, 915, 916, 939, 972, 1005, 1006, 1007, 1008, 1009, 1010,
   1011, 1012, 1013, 1038, 1071, 1072, 1104, 1137, 1170, 1203, 1237, 1238, 1269, 1302, 1335, 1336, 1368, 1401, 1434,
   1467, 1500, 1533, 1534, 1535, 1536, 1537, 1538)
*/


CREATE INDEX IF NOT EXISTS products_retailerId_coreProductId_date_index ON products ("retailerId", "coreProductId", "date");
--[2024-12-06 14:59:31] completed in 6 m 40 s 492 ms
CREATE INDEX IF NOT EXISTS products_retailerId_index ON products ("retailerId");
--[2024-11-28 15:15:32] completed in 6 m 3 s 346 ms
--[2024-12-06 15:05:15] completed in 5 m 43 s 342 ms


DROP TABLE IF EXISTS staging.migration_product_status;
CREATE TABLE staging.migration_product_status AS
SELECT *
FROM "productStatuses"
         INNER JOIN (SELECT products.id AS "productId", "retailerId", "coreProductId", "date"::date
                     FROM products
                     --         INNER JOIN staging.migration_migrated_retailers USING ("retailerId")
                     WHERE "retailerId" NOT IN (1, 2, 3, 8, 10, 13)) AS products
                    USING ("productId");
--[2024-11-28 15:22:52] 27,185,505 rows affected in 6 m 53 s 33 ms
--[2024-12-06 21:06:51] 158,593,065 rows affected in 12 m 16 s 564 ms

--RAISE NOTICE '[%] T001: CREATE staging.migration_product_status:   DONE',CLOCK_TIMESTAMP();

CREATE UNIQUE INDEX migration_product_status_productid_uindex
    ON staging.migration_product_status ("productId");
--[2024-11-28 15:23:25] completed in 16 s 282 ms
--[2024-12-06 21:08:08] completed in 1 m 16 s 108 ms

CREATE INDEX migration_product_status_retailer_coreproduct_date_index
    ON staging.migration_product_status ("retailerId",
                                         "coreProductId",
                                         date);
--[2024-11-28 15:23:49] completed in 23 s 775 ms
--[2024-12-06 21:10:02] completed in 1 m 54 s 142 ms

CREATE INDEX migration_product_status_status_index
    ON staging.migration_product_status (status);
--[2024-11-28 15:24:06] completed in 16 s 633 ms
--[2024-12-06 21:11:28] completed in 1 m 25 s 322 ms

--[2024-11-28 16:36:27] completed in 4 m 29 s 139 ms

/*  DELETE EXTRA De-listed records  */
--RAISE NOTICE '[%] T002: Cleaning of extra `De-listed` records :   STARTED',CLOCK_TIMESTAMP();

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
FROM deleted;
--[2024-11-28 17:34:43] 94,805 rows affected in 2 m 11 s 12 ms
--[2024-12-06 21:28:46] 101,938 rows affected in 8 m 18 s 456 ms

--RAISE NOTICE '[%] T003: INSERT INTO staging.data_corr_status_extra_delisted_deleted:   DONE',CLOCK_TIMESTAMP();

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
--[2024-12-06 21:28:51] 69,543 rows affected in 5 s 346 ms

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
--[2024-12-06 21:29:33] 78,636 rows affected in 9 s 982 ms

--RAISE NOTICE '[%] T004: INSERT INTO staging.data_corr_status_deleted_productsData:   DONE',CLOCK_TIMESTAMP();

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
--[2024-12-06 21:29:50] 439 rows affected in 925 ms

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
--[2024-12-06 21:30:35] 101,938 rows affected in 33 s 125 ms


--RAISE NOTICE '[%] T005: INSERT INTO staging.data_corr_status_deleted_products:   DONE',CLOCK_TIMESTAMP();

DELETE
FROM staging.migration_product_status
    USING staging.data_corr_status_extra_delisted_deleted
WHERE migration_product_status."productId" = data_corr_status_extra_delisted_deleted."productId";
--[2024-12-06 21:30:49] 101,938 rows affected in 879 ms

--RAISE NOTICE '[%] T006: Cleaning of extra `De-listed` records:   DONE',CLOCK_TIMESTAMP();

/*  DELETE EXTRA De-listed records:  END */

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
ORDER BY "retailerId", "coreProductId", load_date;
--[2024-11-28 20:17:47] 26,358,160 rows affected in 2 m 5 s 915 ms
--[2024-12-06 21:43:58] 157,842,968 rows affected in 12 m 33 s 218 ms

--RAISE NOTICE '[%] T007: CREATE staging.migstatus_products_filtered:   DONE',CLOCK_TIMESTAMP();

CREATE INDEX IF NOT EXISTS migstatus_products_filtered_retailerId_coreProductId_date_index
    ON staging.migstatus_products_filtered ("retailerId", "coreProductId", load_date);
--[2024-11-28 20:23:00] completed in 17 s 538 ms
--[2024-12-06 21:45:39] completed in 1 m 40 s 965 ms


--RAISE NOTICE '[%] T008: CREATE migstatus_products_filtered_retailerId_coreProductId_date_index:   DONE',CLOCK_TIMESTAMP();

/*
-ONLY WHEN MIGRATING SAME RETAILER AGAIN
DELETE
FROM staging.product_status_history
WHERE "retailerId" = 1;
 */
--27,156,189 rows affected in 1 m 25 s 103 ms
--RAISE NOTICE '[%] T009: DELETE from staging.product_status_history:   DONE',CLOCK_TIMESTAMP();

CREATE TABLE staging.tmp_product_status_history AS
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
--INSERT INTO staging.product_status_history ("retailerId", "coreProductId", date, "productId", status)
SELECT "retailerId", "coreProductId", date, "productId", status
FROM ins_data;
-- CREATE TABLE [2024-11-28 20:25:49] 27,124,321 rows affected in 1 m 47 s 404 ms
-- INSERT INTO  [2024-11-28 20:58:28] 27,124,321 rows affected in 7 m 25 s 702 ms
-- INSERT INTO  [2024-12-06 22:10:43] [57014] ERROR: canceling statement due to user request
-- CREATE TABLE [2024-12-06 22:24:02] 160,418,596 rows affected in 12 m 30 s 696 ms

--RAISE NOTICE '[%] T010: INSERT INTO staging.product_status_history 1ST PART:   DONE',CLOCK_TIMESTAMP();

WITH last_product_load AS (SELECT "retailerId", "coreProductId", MAX(load_date) AS load_date
                           FROM staging.migstatus_products_filtered
                           GROUP BY "retailerId", "coreProductId"),

     last_retailer_load AS (SELECT "retailerId", MAX(load_date) AS last_load_date
                            FROM staging.migstatus_products_filtered
                            GROUP BY "retailerId")
INSERT
INTO staging.tmp_product_status_history("retailerId", "coreProductId", date, "productId", status)
SELECT "retailerId",
       "coreProductId",
       (load_date + '1 day'::interval)::date AS date,
       NULL                                  AS "productId",
       'De-listed'                           AS status
FROM last_product_load
         INNER JOIN last_retailer_load USING ("retailerId")
WHERE load_date < last_load_date;
-- [2024-11-28 20:59:50] 41,128 rows affected in 9 s 328 ms
--[2024-12-06 22:25:20] 316,576 rows affected in 53 s 402 ms


--RAISE NOTICE '[%] T011: INSERT INTO staging.product_status_history 2ND PART:   DONE',CLOCK_TIMESTAMP();
CREATE INDEX tmp_product_status_history_productid_uindex
    ON staging.tmp_product_status_history ("productId");
--[2024-12-06 22:27:14] completed in 1 m 17 s 121 ms

DROP TABLE IF EXISTS staging."migstatus_productStatuses_additional";

CREATE TABLE staging."migstatus_productStatuses_additional" AS
SELECT "productStatuses".*
FROM staging.migration_product_status AS "productStatuses"
         LEFT OUTER JOIN staging.tmp_product_status_history USING ("productId")-- todo: limit only to the retailers currently being migrated?
WHERE tmp_product_status_history."productId" IS NULL;
--[2024-11-28 21:06:46] 703,455 rows affected in 33 s 789 ms
--[2024-12-06 22:28:14] 648,159 rows affected in 45 s 830 ms

--RAISE NOTICE '[%] T012: CREATE migstatus_productStatuses_additional:   DONE',CLOCK_TIMESTAMP();


CREATE UNIQUE INDEX migstatus_productStatuses_additional_productid_uindex
    ON staging."migstatus_productStatuses_additional" ("productId");

CREATE INDEX migstatus_productStatuses_additional_productid_addindex
    ON staging."migstatus_productStatuses_additional" ("retailerId",
                                                       "coreProductId",
                                                       date);

CREATE INDEX migstatus_productStatuses_additional_productid_statusindex
    ON staging."migstatus_productStatuses_additional" (status);
--RAISE NOTICE '[%] T013: CREATE migstatus_productStatuses_additional INDEXES:   DONE',CLOCK_TIMESTAMP();

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
INTO staging.tmp_product_status_history("retailerId", "coreProductId", date, "productId", status)
SELECT "retailerId",
       "coreProductId",
       date,
       "productId",
       'De-listed' AS status
FROM delisted
WHERE rownum = 1;
/*
ON CONFLICT ("retailerId", "coreProductId", date) --todo: add constraint
    DO UPDATE
    SET "productId"=excluded."productId"
WHERE tmp_product_status_history."productId" IS NULL;

 */
--[2024-11-28 21:12:02] 703,224 rows affected in 30 s 11 ms
--[2024-12-06 22:28:36] 250,119 rows affected in 2 s 694 ms

ALTER TABLE staging.product_status_history
    DROP CONSTRAINT product_status_history_pk;

ALTER TABLE staging.product_status_history
    DROP CONSTRAINT product_status_history_productid_uindex;

INSERT INTO staging.product_status_history("retailerId", "coreProductId", date, "productId", status)
SELECT "retailerId", "coreProductId", date, "productId", status
FROM staging.tmp_product_status_history;
--[2024-12-06 22:37:30] 160,985,291 rows affected in 7 m 34 s 95 ms

CREATE TABLE staging.tmp_dup_prod_stat_history AS
WITH dup AS (SELECT *,
                    ROW_NUMBER()
                    OVER (PARTITION BY "retailerId", "coreProductId", date ORDER BY "productId" DESC NULLS LAST) AS rownum
             FROM staging.product_status_history)
SELECT "retailerId",
       "coreProductId",
       date,
       "productId",
       status
FROM dup
WHERE rownum > 1;

CREATE TABLE staging.tmp_mig2nd_fix_dup_status AS
WITH ins_ AS (SELECT *,
                     ROW_NUMBER()
                     OVER (PARTITION BY "retailerId", "coreProductId", date ORDER BY CASE
                                                                                         WHEN status = 'De-listed'
                                                                                             THEN 99
                                                                                         ELSE 1 END,
                         "productId" DESC NULLS LAST) AS rownum
              FROM (SELECT "retailerId", "coreProductId", date, "productId" AS tmp_productId
                    FROM staging.tmp_dup_prod_stat_history) AS tmp
                       INNER JOIN staging.product_status_history USING ("retailerId", "coreProductId", date)
              ORDER BY "retailerId", "coreProductId", date)
SELECT "retailerId",
       "coreProductId",
       date,
       "productId",
       status
FROM ins_
WHERE rownum = 1;

DELETE
FROM staging.product_status_history USING staging.tmp_dup_prod_stat_history AS dup
WHERE product_status_history."retailerId" = dup."retailerId"
  AND product_status_history."coreProductId" = dup."coreProductId"
  AND product_status_history.date = dup.date;

INSERT INTO staging.product_status_history
SELECT "retailerId",
       "coreProductId",
       date,
       "productId",
       status
FROM staging.tmp_mig2nd_fix_dup_status;

/*  TODO: CONTINUE FROM HERE   <<<<    */
ALTER TABLE staging.product_status_history
    ADD CONSTRAINT product_status_history_pk
        PRIMARY KEY ("retailerId", "coreProductId", date);
--[2024-12-06 23:08:18] completed in 2 m 3 s 32 ms

ALTER TABLE staging.product_status_history
    ADD CONSTRAINT product_status_history_productid_uindex
        UNIQUE ("productId");
--[2024-12-06 23:09:48] completed in 1 m 29 s 526 ms


--RAISE NOTICE '[%] T014: INSERT INTO staging.product_status_history 3RD PART (ADDITIONAL):   DONE',CLOCK_TIMESTAMP();

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


DROP TABLE IF EXISTS staging.migstatus_delisted;
CREATE TABLE staging.migstatus_delisted AS
SELECT "retailerId",
       "coreProductId",
       "date" AS delisted_date
FROM staging.product_status_history -- todo: limit only to the retailers currently being migrated? NOT NEEDED, as already migrated retailers do not have records where productId is null.
WHERE "productId" IS NULL;
--[2024-12-06 23:27:34] 2,643,250 rows affected in 7 s 878 ms

ALTER TABLE staging.migstatus_delisted
    ADD CONSTRAINT migstatus_delisted_pk
        PRIMARY KEY (delisted_date, "coreProductId", "retailerId");

CREATE TABLE staging.migstatus_last_load_product AS
SELECT delisted."retailerId",
       delisted."coreProductId",
       delisted.delisted_date,
       MAX(product.load_date) AS load_date
FROM staging.migstatus_delisted AS delisted
         INNER JOIN staging.migstatus_products_filtered AS product
                    ON (product."retailerId" = delisted."retailerId" AND
                        product."coreProductId" = delisted."coreProductId" AND
                        product.load_date < delisted.delisted_date)
GROUP BY delisted."retailerId",
         delisted."coreProductId",
         delisted.delisted_date;
--[2024-12-06 23:46:00] 2,643,250 rows affected in 48 s 399 ms

CREATE TABLE staging.migstatus_ins_prod_selection AS
SELECT "productId" AS id,
       delisted_date,
       dates.id    AS delisted_date_id
FROM staging.migstatus_products_filtered
         INNER JOIN staging.migstatus_last_load_product AS last_load_product
                    USING ("retailerId", "coreProductId", load_date)
         LEFT OUTER JOIN dates ON (dates."date" = delisted_date);
--[2024-12-06 23:48:38] 2,643,250 rows affected in 11 s 285 ms
ALTER TABLE staging.migstatus_ins_prod_selection
    ADD CONSTRAINT migstatus_ins_prod_selection_pk
        PRIMARY KEY (id);


DROP TABLE IF EXISTS staging.migstatus_ins_products;
CREATE TABLE staging.migstatus_ins_products AS
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
         INNER JOIN staging.migstatus_ins_prod_selection AS ins_prod_selection USING (id);
--[2024-11-28 21:13:47] 104,440 rows affected in 14 s 760 ms
--[2024-12-06 23:54:47] 2,643,250 rows affected in 3 m 53 s 669 ms


--RAISE NOTICE '[%] T015: CREATE staging.migstatus_ins_products:   DONE',CLOCK_TIMESTAMP();

INSERT
INTO products
SELECT*
FROM staging.migstatus_ins_products;
--3,310,580 rows affected in 31 m 23 s 196 ms
--[2024-12-07 00:38:58] 2,643,250 rows affected in 44 m 1 s 899 ms

--RAISE NOTICE '[%] T016: INSERT INTO PRODUCTS:   DONE',CLOCK_TIMESTAMP();


UPDATE staging.product_status_history AS history
SET "productId"=ins_products.id
FROM staging.migstatus_ins_products AS ins_products
WHERE history."retailerId" = ins_products."retailerId"
  AND history."coreProductId" = ins_products."coreProductId"
  AND history.date = ins_products.date;
-- 2,752,620 rows affected in 9 m 4 s 600 ms
--[2024-12-07 00:44:51] 2,643,250 rows affected in 5 m 51 s 955 ms

--RAISE NOTICE '[%] T017: UPDATED staging.product_status_history:   DONE',CLOCK_TIMESTAMP();

/*  TODO: CONTINUE FROM HERE   <<<<    */
WITH deleted AS (
    DELETE FROM "productStatuses"
        USING staging.migration_product_status WHERE
            "productStatuses"."productId" = migration_product_status."productId"
        --AND migration_product_status."retailerId" = 1 OBSOLETE,  migration_product_status has >>all and only<< the retailers being migrated
        RETURNING "productStatuses".*)
INSERT
INTO staging.data_corr_ret_mig_prod_status_bck
SELECT *
FROM deleted;
--[2024-11-29 20:22:06] 27,144,256 rows affected in 6 m 40 s 703 ms
--[2024-12-07 01:46:18] 158,491,127 rows affected in 1 h 1 m 26 s 225 ms

--RAISE NOTICE '[%] T018: DELETE FROM "productStatuses":   DONE',CLOCK_TIMESTAMP();


ALTER TABLE staging.data_corr_ret_mig_prod_status_bck
    ADD CONSTRAINT data_corr_ret_mig_prod_status_bck_pk
        PRIMARY KEY ("productId");
--[2024-12-07 01:49:26] completed in 1 m 25 s 516 ms

SET work_mem = '4GB';
SET max_parallel_workers_per_gather = 4;
SHOW WORK_MEM;
SHOW max_parallel_workers_per_gather;


DROP TABLE staging.migret_ins_productstatuses1;
CREATE TABLE staging.migret_ins_productstatuses1 AS
SELECT "productStatuses".id,
       "productId",
       product_status_history.status,
       "productStatuses".screenshot,
       "productStatuses"."createdAt",
       "productStatuses"."updatedAt",
       "productStatuses".load_id
FROM staging.product_status_history
         INNER JOIN staging.data_corr_ret_mig_prod_status_bck AS "productStatuses" USING ("productId");
--[2024-11-29 20:29:59] 27,115,721 rows affected in 1 m 51 s 349 ms
--[2024-12-07 02:23:44] 158,092,158 rows affected in 32 m 15 s 509 ms

/*  completed */
CREATE TABLE staging.migret_ins_productstatuses2 AS
SELECT "productId",
       product_status_history.status
FROM staging.product_status_history
         LEFT OUTER JOIN staging.data_corr_ret_mig_prod_status_bck AS "productStatuses" USING ("productId")
WHERE product_status_history."retailerId" != 1 --tesco
  AND "productStatuses".id IS NULL;
--[2024-11-29 20:46:51] 54,197 rows affected in 55 s 304 ms
--[2024-12-07 01:57:03] 2,643,250 rows affected in 1 m 7 s 251 ms



SET work_mem = '4GB';
SET max_parallel_workers_per_gather = 4;
SHOW WORK_MEM;
SHOW max_parallel_workers_per_gather;
/*  disable constraints on "productStatuses" */
ALTER TABLE public."productStatuses"
    DROP CONSTRAINT "productStatuses_pkey",
    DROP CONSTRAINT productstatuses_products_id_fk;

ALTER TABLE "productStatuses"
    DROP CONSTRAINT "productStatuses_productId_uq";



INSERT INTO "productStatuses"(id,
                              "productId",
                              status,
                              screenshot,
                              "createdAt",
                              "updatedAt",
                              load_id)
SELECT id,
       "productId",
       status,
       screenshot,
       "createdAt",
       "updatedAt",
       load_id
FROM staging.migret_ins_productstatuses1;
--[2024-11-29 20:45:38] 27,115,721 rows affected in 1 m 48 s 751 ms
--[2024-12-07 03:21:18] 158,092,158 rows affected in 48 m 17 s 62 ms


INSERT INTO "productStatuses"("productId",
                              status,
                              screenshot,
                              "createdAt",
                              "updatedAt",
                              load_id)
SELECT "productId",
       status,
       NULL              AS screenshot,
       CURRENT_TIMESTAMP AS "createdAt",
       CURRENT_TIMESTAMP AS "updatedAt",
       NULL              AS load_id
FROM staging.migret_ins_productstatuses2;
--[2024-11-29 20:47:05] 54,197 rows affected in 335 ms
--[2024-12-07 03:24:10] 2,643,250 rows affected in 39 s 354 ms


/*  re-create constraints on "productStatuses" */
ALTER TABLE public."productStatuses"
    ADD CONSTRAINT "productStatuses_pkey" PRIMARY KEY (id);
--[2024-11-29 20:56:03] completed in 2 m 23 s 344 ms
--[2024-12-07 03:26:34] completed in 2 m 23 s 676 ms

--CREATE UNIQUE INDEX productstatuses_productid_uindex ON public."productStatuses" ("productId");
ALTER TABLE public."productStatuses"
    ADD CONSTRAINT "productStatuses_productId_uq" UNIQUE ("productId");
--[2024-11-29 21:08:56] completed in 2 m 27 s 622 ms
--[2024-12-07 03:28:57] completed in 2 m 22 s 476 ms
/*  TODO: CONTINUE FROM HERE   <<<<    */
ALTER TABLE public."productStatuses"
    ADD CONSTRAINT productstatuses_products_id_fk
        FOREIGN KEY ("productId") REFERENCES public.products;
--[2024-11-29 21:05:35] completed in 9 m 31 s 48 ms
--


/*
not relevant, as it only updates retailers from current migration
UPDATE staging.migration_migrated_retailers
SET migration_end=CLOCK_TIMESTAMP();
WHERE "retailerId" = 1;
*/


/*  TODO: CONTINUE FROM HERE   <<<<    */

/*  completed */
CREATE TABLE migration.ms2_mig_prod_stat_multiple_in_same_day AS
WITH missing_product_statuses AS (SELECT data_corr_ret_mig_prod_status_bck.*
                                  FROM staging.data_corr_ret_mig_prod_status_bck
                                           LEFT OUTER JOIN "productStatuses" USING ("productId")
                                  WHERE "productStatuses"."productId" IS NULL)
SELECT *
FROM missing_product_statuses;
--[2024-12-07 02:07:51] 158,491,127 rows affected in 8 m 27 s 46 ms
--[2024-12-07 03:39:02] 398,969 rows affected in 1 m 17 s 311 ms


--[2024-11-29 21:21:58] completed in 10 m 22 s 469 ms

--VACUUM FULL "products";


ALTER TABLE staging.data_corr_ret_mig_prod_status_bck  RENAME TO ms2_data_corr_ret_mig_prod_status_bck;
ALTER TABLE staging.ms2_data_corr_ret_mig_prod_status_bck  set SCHEMA data_corr;

ALTER TABLE staging.data_corr_status_deleted_aggregatedproducts  RENAME TO ms2_data_corr_status_deleted_aggregatedproducts;
ALTER TABLE staging.ms2_data_corr_status_deleted_aggregatedproducts  set SCHEMA data_corr;

ALTER TABLE staging.data_corr_status_deleted_products  RENAME TO ms2_data_corr_status_deleted_products;
ALTER TABLE staging.ms2_data_corr_status_deleted_products  set SCHEMA data_corr;

ALTER TABLE staging.data_corr_status_deleted_productsdata  RENAME TO ms2_data_corr_status_deleted_productsdata;
ALTER TABLE staging.ms2_data_corr_status_deleted_productsdata  set SCHEMA data_corr;

ALTER TABLE staging.data_corr_status_deleted_promotions  RENAME TO ms2_data_corr_status_deleted_promotions;
ALTER TABLE staging.ms2_data_corr_status_deleted_promotions  set SCHEMA data_corr;

ALTER TABLE staging.migration_migrated_retailers  RENAME TO ms2_migration_migrated_retailers;
ALTER TABLE staging.ms2_migration_migrated_retailers  set SCHEMA migration;


ALTER TABLE staging.migration_product_status  RENAME TO ms2_migration_product_status;
ALTER TABLE staging.ms2_migration_product_status  set SCHEMA migration;


ALTER TABLE staging.migret_ins_productstatuses1  RENAME TO ms2_migret_ins_productstatuses1;
ALTER TABLE staging.ms2_migret_ins_productstatuses1  set SCHEMA migration;


ALTER TABLE staging.migret_ins_productstatuses2  RENAME TO ms2_migret_ins_productstatuses2;
ALTER TABLE staging.ms2_migret_ins_productstatuses2  set SCHEMA migration;


ALTER TABLE staging.migstatus_delisted  RENAME TO ms2_migstatus_delisted;
ALTER TABLE staging.ms2_migstatus_delisted  set SCHEMA migration;


ALTER TABLE staging.migstatus_ins_prod_selection  RENAME TO ms2_migstatus_ins_prod_selection;
ALTER TABLE staging.ms2_migstatus_ins_prod_selection  set SCHEMA migration;


ALTER TABLE staging.migstatus_ins_products  RENAME TO ms2_migstatus_ins_products;
ALTER TABLE staging.ms2_migstatus_ins_products  set SCHEMA migration;



ALTER TABLE staging.migstatus_last_load_product  RENAME TO ms2_migstatus_last_load_product;
ALTER TABLE staging.ms2_migstatus_last_load_product  set SCHEMA migration;


ALTER TABLE staging.migstatus_products_filtered  RENAME TO ms2_migstatus_products_filtered;
ALTER TABLE staging.ms2_migstatus_products_filtered  set SCHEMA migration;


ALTER TABLE staging."migstatus_productStatuses_additional"  RENAME TO "ms2_migstatus_productStatuses_additional";
ALTER TABLE staging."ms2_migstatus_productStatuses_additional"  set SCHEMA migration;


ALTER TABLE staging.tmp_mig2nd_dup_prod_stat_history  RENAME TO ms2_tmp_mig2nd_dup_prod_stat_history;
ALTER TABLE staging.ms2_tmp_mig2nd_dup_prod_stat_history  set SCHEMA migration;


ALTER TABLE staging.tmp_mig2nd_fix_dup_status  RENAME TO ms2_tmp_mig2nd_fix_dup_status;
ALTER TABLE staging.ms2_tmp_mig2nd_fix_dup_status  set SCHEMA migration;


ALTER TABLE staging.tmp_mig2nd_product_status_history  RENAME TO ms2_tmp_mig2nd_product_status_history;
ALTER TABLE staging.ms2_tmp_mig2nd_product_status_history  set SCHEMA migration;



/*
+----------+--------+
|retailerId|count   |
+----------+--------+
|1         |28337011|
|4         |679202  |
|9         |21485433|
|11        |6005668 |
|48        |4026126 |
|81        |4980200 |
|114       |2324534 |
|159       |34561115|
|345       |19176634|
|378       |1475850 |
|411       |766135  |
|444       |650836  |
|477       |796389  |
|510       |3071477 |
|543       |1107819 |
|609       |11201876|
|642       |5456633 |
|675       |218701  |
|708       |3286294 |
|741       |1144398 |
|774       |5639751 |
|775       |99344   |
|807       |2094108 |
|840       |47188   |
|873       |347210  |
|906       |288074  |
|907       |285010  |
|908       |285280  |
|909       |285727  |
|910       |312968  |
|911       |239928  |
|912       |273207  |
|913       |285143  |
|914       |286407  |
|915       |325276  |
|916       |306472  |
|939       |45556   |
|972       |1197161 |
|1005      |35701   |
|1006      |39329   |
|1007      |23383   |
|1008      |51282   |
|1009      |43575   |
|1010      |40647   |
|1011      |37584   |
|1012      |34518   |
|1013      |18820   |
|1038      |363983  |
|1071      |120268  |
|1072      |111195  |
|1104      |2447955 |
|1137      |1048597 |
|1170      |1449981 |
|1269      |1130818 |
|1302      |2695592 |
|1335      |4628311 |
|1336      |2675516 |
|1368      |1258276 |
|1401      |879650  |
|1434      |1509060 |
|1467      |447369  |
|1500      |1289806 |
|1533      |923260  |
|1534      |423266  |
|1535      |1083838 |
|1538      |864698  |
+----------+--------+
*/