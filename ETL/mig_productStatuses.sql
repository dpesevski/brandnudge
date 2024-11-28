/*
SET work_mem = '4GB';
SET max_parallel_workers_per_gather = 4;
*/

CREATE INDEX products_retailerId_coreProductId_date_index
    ON products ("retailerId", "coreProductId", date); --[2024-11-16 14:44:02] completed in 10 m 52 s 449 ms

CREATE TABLE staging.migstatus_products_filtered AS
WITH products AS (SELECT "retailerId",
                         "coreProductId",
                         load_date,
                         "productId",
                         ROW_NUMBER()
                         OVER (PARTITION BY "retailerId","coreProductId", load_date ORDER BY "productId" DESC) AS rownum
                  FROM (SELECT "retailerId",
                               "coreProductId",
                               date::date AS load_date,
                               id         AS "productId"
                        FROM products) AS products
                           LEFT OUTER JOIN (SELECT "productId"
                                            FROM "productStatuses"
                                            WHERE "productStatuses".status IN ('de-listed', 'De-listed')) AS delisted
                                           USING ("productId")
                  WHERE delisted."productId" IS NULL)
SELECT "retailerId",
       "coreProductId",
       load_date,
       "productId"
FROM products
WHERE rownum = 1
ORDER BY "retailerId", "coreProductId", load_date; --282,823,990 rows affected in 36 m 44 s 565 ms

CREATE INDEX migstatus_products_filtered_retailerId_coreProductId_date_index
    ON staging.migstatus_products_filtered ("retailerId", "coreProductId", load_date); --completed in 4 m 42 s 756 ms

CREATE TABLE staging.product_status_history AS
WITH retailer_product_load AS (SELECT "retailerId",
                                      "coreProductId",
                                      load_date,
                                      "productId",
                                      LAG(load_date)
                                      OVER (PARTITION BY "retailerId","coreProductId" ORDER BY load_date) AS prev_load_date
                               FROM staging.migstatus_products_filtered)
SELECT "retailerId",
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
WHERE prev_load_date < load_date - '1 day'::interval; -- 287,123,639 rows affected in 44 m 32 s 925 ms

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
WHERE load_date < last_load_date; -- 495,353 rows affected in 1 m 41 s 352 ms

ALTER TABLE staging.product_status_history
    ADD CONSTRAINT product_status_history_pk
        PRIMARY KEY ("retailerId",
                     "coreProductId",
                     date); -- completed in 5 m 38 s 907 ms

CREATE UNIQUE INDEX product_status_history_productid_uindex
    ON staging.product_status_history ("productId"); --completed in 3 m 19 s 17 ms


DROP TABLE IF EXISTS staging."migstatus_productStatuses_additional";
-- [2024-11-16 13:01:45] completed in 61 ms
/*
-- original script
CREATE TABLE staging."migstatus_productStatuses_additional" AS
WITH status AS (SELECT "productStatuses".*
                FROM "productStatuses"
                         LEFT OUTER JOIN staging.product_status_history USING ("productId")
                WHERE product_status_history."productId" IS NULL)
SELECT status.*,
       "retailerId",
       "coreProductId",
       date::date
FROM status
         INNER JOIN products ON (products.id = status."productId"); -- 2,828,629 rows affected in 6 m 17 s 129 ms
*/
CREATE TABLE staging."migstatus_productStatuses_all" AS
SELECT *
FROM "productStatuses"
         INNER JOIN (SELECT id AS "productId", "retailerId", "coreProductId", "date"::date FROM products) AS products
                    USING ("productId");

CREATE UNIQUE INDEX migstatus_migstatus_productStatuses_all_productid_uindex
    ON staging."migstatus_productStatuses_all" ("productId");
/*
CREATE INDEX migstatus_migstatus_productStatuses_all_productid_addindex
    ON staging."migstatus_productStatuses_all" ("retailerId",
                                      "coreProductId",
                                      date);
CREATE INDEX migstatus_migstatus_productStatuses_all_productid_statusindex
    ON staging."migstatus_productStatuses_all" (status);
*/

CREATE TABLE staging."migstatus_productStatuses_additional" AS
SELECT "productStatuses".*
FROM staging."migstatus_productStatuses_all" AS "productStatuses"
         LEFT OUTER JOIN staging.product_status_history USING ("productId")
WHERE product_status_history."productId" IS NULL;
-- 2,945,110 rows affected in 12 m 24 s 117 ms


CREATE UNIQUE INDEX migstatus_productStatuses_additional_productid_uindex
    ON staging."migstatus_productStatuses_additional" ("productId");

CREATE INDEX migstatus_productStatuses_additional_productid_addindex
    ON staging."migstatus_productStatuses_additional" ("retailerId",
                                                       "coreProductId",
                                                       date);
CREATE INDEX migstatus_productStatuses_additional_productid_statusindex
    ON staging."migstatus_productStatuses_additional" (status);

/*  handle records with De-listed status */

/*  TO DO:  a. keep existing "De-listed" records in productStatuses and
            b. create additional "De-listed" records in productStatuses and
                 b.1 extend productStatusses with ("retailerId", "coreProductId", date) and use these to join with product_status_history below instead of "productId"
                 b.2 create records in products for the delisted status records with no productId set. Update back the productId in productStatuses.

*/

/*
SELECT status, "productId" IS NULL as delisted, COUNT(*)
FROM staging.product_status_history
GROUP BY 1, 2;

+---------+--------+---------+
|status   |delisted|count    |
+---------+--------+---------+
|De-listed|true    |  5321490|
|Listed   |false   |266615171|
|Newly    |false   |  1086394|
|Re-listed|false   |  4883591|
+---------+--------+---------+
*/
/*`TO DO: maybe only update without insert?
  All records in productStatsuses with status "Delisted" are relating to en existing record in products, made only for the purpose to record status "Delisted"
  Some of these product records may have been created wrongly, and should be removed.
  Till then, we can keep these records both in productStatsuses and products.
  */
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
--2,357,894 rows affected in 5 m 21 s 290 ms
--2,433,337 rows affected in 18 m 56 s 768 ms
--  AND product_status_history.status = 'De-listed' -- implicitly, only de-listed have null "productId"

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
-- 3,310,580 rows affected in 27 m 3 s 761 ms
--2,752,620 rows affected in 1 h 3 m 18 s 404 ms

INSERT
INTO products
SELECT*
FROM staging.migstatus_ins_products;
--3,310,580 rows affected in 31 m 23 s 196 ms
--2,752,620 rows affected in 45 m 57 s 832 ms


UPDATE staging.product_status_history AS history
SET "productId"=ins_products.id
FROM staging.migstatus_ins_products AS ins_products
WHERE history."retailerId" = ins_products."retailerId"
  AND history."coreProductId" = ins_products."coreProductId"
  AND history.date = ins_products.date;
-- 2,752,620 rows affected in 9 m 4 s 600 ms
/*
[2024-11-18 11:13:14] completed in 83 ms
brandnudge-dev.public> CREATE TABLE staging."productStatuses" AS
                       SELECT COALESCE("productStatuses".id, NEXTVAL('"productStatuses_id_seq"'::regclass)) AS id,
                              "productId",
                              product_status_history.status,
                              "productStatuses".screenshot,
                              COALESCE("productStatuses"."createdAt", CURRENT_TIMESTAMP)                    AS "createdAt",
                              COALESCE("productStatuses"."updatedAt", CURRENT_TIMESTAMP)                    AS "updatedAt",
                              "productStatuses".load_id
                       FROM staging.product_status_history
                                LEFT OUTER JOIN public."productStatuses" USING ("productId")
[2024-11-18 11:26:43] An I/O error occurred while sending to the backend.
*/
/*
3 minutes
============================
[2024-11-14 18:49:00] [23505] ERROR: duplicate key value violates unique constraint "products_sourceid_retailerid_dateid_key"
[2024-11-14 18:49:00] Detail: Key ("sourceId", "retailerId", "dateId")=(7428221, 3, 162) already exists.
*/

DROP TABLE IF EXISTS staging."productStatuses";
CREATE TABLE staging."productStatuses" AS
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

/*
/* Add additional records with statsus !='De-listed' which were missing in the "productStatuses"  */
INSERT INTO staging."productStatuses" ("productId", status, "createdAt", "updatedAt")
SELECT product_status_history."productId",
       product_status_history.status,
       CURRENT_TIMESTAMP,
       CURRENT_TIMESTAMP
FROM staging.product_status_history
         LEFT OUTER JOIN public."productStatuses" USING ("productId")
WHERE "productStatuses".id IS NULL
  AND product_status_history."productId" IS NOT NULL;
*/


ALTER TABLE "productStatuses"
    ALTER COLUMN id DROP DEFAULT;

ALTER TABLE staging."productStatuses"
    ALTER COLUMN id SET DEFAULT NEXTVAL('"productStatuses_id_seq"'::regclass);

ALTER TABLE public."productStatuses"
    RENAME TO "productStatuses-bck";
ALTER INDEX "productStatuses_pkey" RENAME TO "productStatuses-bck_pkey";
ALTER INDEX "productstatuses_productid_uindex" RENAME TO "productstatuses-bck_productid_uindex";

ALTER TABLE staging."productStatuses"
    SET SCHEMA public;

CREATE UNIQUE INDEX "productStatuses_pkey"
    ON public."productStatuses" (id);

CREATE UNIQUE INDEX productstatuses_productid_uindex
    ON public."productStatuses" ("productId");

