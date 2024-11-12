/*
SET work_mem = '4GB';
SET max_parallel_workers_per_gather = 4;

CREATE INDEX products_retailerId_coreProductId_date_index
    ON products ("retailerId", "coreProductId", date);
*/

CREATE TABLE staging.migstatus_products_filtered AS
WITH products AS (SELECT products."retailerId",
                         products."coreProductId",
                         products.load_date,
                         "productId",
                         ROW_NUMBER()
                         OVER (PARTITION BY "retailerId","coreProductId", load_date ORDER BY "productId" DESC) AS rownum
                  FROM (SELECT "retailerId",
                               "coreProductId",
                               date::date,
                               products.id AS "productId"
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
ORDER BY "retailerId", "coreProductId", load_date; --272,585,156 rows affected in 31 m 38 s 734 ms

CREATE INDEX migstatus_products_filtered_retailerId_coreProductId_date_index
    ON staging.migstatus_products_filtered ("retailerId", "coreProductId", load_date);

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
WHERE prev_load_date < load_date - '1 day'::interval; -- 277,468,747 rows affected in 40 m 33 s 675 ms

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
WHERE load_date < last_load_date; -- 437,899 rows affected in 1 m 34 s 410 ms

ALTER TABLE staging.product_status_history
    ADD CONSTRAINT product_status_history_pk
        PRIMARY KEY ("retailerId",
                     "coreProductId",
                     date); -- completed in 3 m 39 s 842 ms

CREATE UNIQUE INDEX product_status_history_productid_uindex
    ON staging.product_status_history ("productId");
--completed in 2 m 29 s 225 ms

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


/*  handle records with De-listed status */

/*  TO DO:  a. keep existing "De-listed" records in productStatuses and products.
            b. create additional "De-listed" records in productStatuses and products.
                 b.1 extend productStatusses with ("retailerId", "coreProductId", date) and use these to join with product_status_history below instead of "productId"
                 b.2 create records in products for the delisted status records with no productId set. Update back the productId in productStatuses.

*/
DROP TABLE IF EXISTS staging."migstatus_productStatuses_additional";
CREATE TABLE staging."migstatus_productStatuses_additional" AS
WITH status AS (SELECT "productStatuses".*
                FROM "productStatuses"
                         LEFT OUTER JOIN staging.product_status_history USING ("productId")
                WHERE product_status_history."productId" IS NULL)
SELECT status.*,
       products."retailerId",
       products."coreProductId",
       products.date::date
FROM status
         INNER JOIN products ON (products.id = status."productId"); -- 2,828,629 rows affected in 6 m 17 s 129 ms

CREATE UNIQUE INDEX migstatus_productStatuses_additional_productid_uindex
    ON staging."migstatus_productStatuses_additional" ("productId");

CREATE INDEX migstatus_productStatuses_additional_productid_addindex
    ON staging."migstatus_productStatuses_additional" ("retailerId",
                                                       "coreProductId",
                                                       date);
CREATE INDEX migstatus_productStatuses_additional_productid_statusindex
    ON staging."migstatus_productStatuses_additional" (status);


SELECT status, COUNT(*)
FROM staging."migstatus_productStatuses_additional"
GROUP BY status;

SELECT *
FROM staging."migstatus_productStatuses_additional";


/*
SELECT status, "productId" IS NULL, COUNT(*)
FROM staging.product_status_history
GROUP BY 1, 2;

+---------+--------+---------+
|status   |?column?|count    |
+---------+--------+---------+
|De-listed|true    |5321490  |
|Listed   |false   |266615171|
|Newly    |false   |1086394  |
|Re-listed|false   |4883591  |
+---------+--------+---------+

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
WHERE product_status_history."productId" IS NULL;--
--  AND product_status_history.status = 'De-listed' -- implicitly, only de-listed have productid=null



CREATE TABLE staging."productStatuses" AS
SELECT "productStatuses".id,
       "productId",
       product_status_history.status,
       "productStatuses".screenshot,
       "productStatuses"."createdAt",
       "productStatuses"."updatedAt",
       "productStatuses".load_id
FROM staging.product_status_history
         INNER JOIN public."productStatuses" USING ("productId");--271,828,761 rows affected in 21 m 46 s 957 ms

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


/*  [23505] ERROR: could not create unique index "product_status_history_pk" Detail: Key ("retailerId", "coreProductId", load_date)=(1, 48, 2021-05-08) is duplicated.  */


CREATE TABLE staging.PRODUCT_STATUS AS
WITH PRODUCT_STATUS AS (SELECT *,
                               ROW_NUMBER()
                               OVER (PARTITION BY "retailerId", "coreProductId" ORDER BY load_date DESC) AS rownum
                        FROM staging.product_status_history)
SELECT "retailerId",
       "coreProductId",
       load_date,
       status
FROM PRODUCT_STATUS
WHERE rownum = 1;

ALTER TABLE staging.PRODUCT_STATUS
    ADD CONSTRAINT PRODUCT_STATUS_pk
        PRIMARY KEY ("retailerId",
                     "coreProductId");
