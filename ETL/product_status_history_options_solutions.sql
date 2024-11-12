/*SELECT *
FROM staging.product_status
WHERE "sourceId" = '250411816';

SELECT *
FROM staging.products_last
WHERE "sourceId" = '250411816';

SELECT *
FROM "coreRetailers"
WHERE id = 651096;
*/

SELECT *
FROM pg_settings
ORDER BY category, name;

SET WORK_MEM = '4GB';
SET max_parallel_workers_per_gather = 4;


ALTER TABLE staging.retailer_product_load
    ADD CONSTRAINT ret_prod_pk
        PRIMARY KEY ("retailerId",
                     "coreProductId",
                     load_date);

/*  solution "A", using table public.products */
CREATE INDEX products_retailerId_coreProductId_date_index
    ON products ("retailerId", "coreProductId", date);

CREATE TABLE staging.retailer_product_load AS
WITH retailer_product_load AS (SELECT "retailerId",
                                      "coreProductId",
                                      ROW_NUMBER()
                                      OVER (PARTITION BY "retailerId", "coreProductId" ORDER BY date DESC) AS load_id,
                                      date::date                                                           AS load_date
                               FROM products)
SELECT *
FROM retailer_product_load
ORDER BY 1, 2, 3;


/*  solution "b", using table public.coreRetailerDates */
CREATE TABLE staging.retailer_product_load AS
WITH retailer_product_load AS (SELECT "retailerId",
                                      "coreProductId",
                                      ROW_NUMBER()
                                      OVER (PARTITION BY "retailerId", "coreProductId" ORDER BY date DESC) AS load_id,
                                      date::date                                                           AS load_date
                               FROM "coreRetailerDates"
                                        INNER JOIN "coreRetailers"
                                                   ON ("coreRetailers".id = "coreRetailerDates"."coreRetailerId")
                                        INNER JOIN dates ON (dates.id = "coreRetailerDates"."dateId"))
SELECT *
FROM retailer_product_load
ORDER BY 1, 2, 3;


ALTER TABLE staging.retailer_product_load
    ADD CONSTRAINT ret_prod_pk
        PRIMARY KEY ("retailerId",
                     "coreProductId",
                     load_id);

CREATE TABLE staging.product_status_history AS
WITH last_retailer_load AS (SELECT "retailerId", MAX(load_date) AS last_load_date
                            FROM staging.retailer_product_load
                            GROUP BY "retailerId"),
     status_base AS (SELECT load."retailerId",
                            load."coreProductId",
                            load.load_id,
                            load.load_date,
                            prev_load.load_date AS prev_load_date,
                            status
                     FROM staging.retailer_product_load AS load
                              LEFT OUTER JOIN staging.retailer_product_load AS prev_load
                                              ON (prev_load."retailerId" = load."retailerId"
                                                  AND prev_load."coreProductId" = load."coreProductId"
                                                  AND prev_load.load_id = load.load_id + 1
                                                  )
                              CROSS JOIN LATERAL (SELECT CASE
                                                             WHEN prev_load.load_date IS NULL THEN 'Newly'
                                                             --    to do: the expression never evalueates to 'Listed'
                                                             WHEN prev_load.load_date = load.load_date - '1 day'::interval
                                                                 THEN 'Listed'
                                                             ELSE 'Re-listed'
                                                             END AS status
                         ) AS lat),
     product_status AS (SELECT "retailerId",
                               "coreProductId",
                               load_date AS date,
                               status
                        FROM status_base

                        UNION ALL

                        SELECT "retailerId",
                               "coreProductId",
                               (prev_load_date + '1 day'::interval)::date AS date,
                               'De-listed'                                AS status
                        FROM status_base
                        WHERE status = 'Re-listed'

                        UNION ALL

                        SELECT "retailerId",
                               "coreProductId",
                               (load_date + '1 day'::interval)::date AS date,
                               'De-listed'                           AS status
                        FROM status_base
                                 INNER JOIN last_retailer_load USING ("retailerId")
                        WHERE load_id = 1
                          AND load_date < last_load_date)
SELECT *
FROM product_status
ORDER BY "retailerId",
         "coreProductId",
         date;


/*  solution "C",  using index in public.products, and lag(date) */

SET WORK_MEM = '4GB';
SET max_parallel_workers_per_gather = 4;

CREATE INDEX products_retailerId_coreProductId_date_index
    ON products ("retailerId", "coreProductId", date);

CREATE TABLE staging.product_status_history AS
WITH products AS (SELECT "retailerId",
                         "coreProductId",
                         load_date,
                         id                                                                           AS "productId",
                         ROW_NUMBER()
                         OVER (PARTITION BY "retailerId","coreProductId", load_date ORDER BY id DESC) AS rownum
                  FROM public.products
                           CROSS JOIN LATERAL (SELECT date::date AS load_date) AS lat),
     retailer_product_load AS (SELECT "retailerId",
                                      "coreProductId",
                                      load_date,
                                      "productId",
                                      LAG(load_date)
                                      OVER (PARTITION BY "retailerId","coreProductId" ORDER BY load_date) AS prev_load_date
                               FROM products
                               WHERE rownum = 1)
SELECT "retailerId",
       "coreProductId",
       load_date,
       "productId",
       CASE
           WHEN prev_load_date IS NULL THEN 'Newly'
           WHEN prev_load_date = load_date - '1 day'::interval
               THEN 'Listed'
           ELSE 'Re-listed'
           END AS status
FROM retailer_product_load

UNION ALL

SELECT "retailerId",
       "coreProductId",
       (prev_load_date + '1 day'::interval)::date AS load_date,
       NULL                                       AS "productId",
       'De-listed'                                AS status
FROM retailer_product_load
WHERE prev_load_date < load_date - '1 day'::interval; --277,443,221 rows affected in 35 m 59 s 735 ms

WITH last_product_load AS (SELECT "retailerId", "coreProductId", MAX(date) AS load_date
                           FROM products
                           GROUP BY "retailerId", "coreProductId"),

     last_retailer_load AS (SELECT "retailerId", MAX(date) AS last_load_date
                            FROM products
                            GROUP BY "retailerId")
INSERT
INTO staging.product_status_history("retailerId", "coreProductId", load_date, "productId", status)
SELECT "retailerId",
       "coreProductId",
       (load_date + '1 day'::interval)::date AS load_date,
       NULL                                  AS "productId",
       'De-listed'                           AS status
FROM last_product_load
         INNER JOIN last_retailer_load USING ("retailerId")
WHERE load_date < last_load_date; --435,639 rows affected in 14 m 35 s 871 ms

ALTER TABLE staging.product_status_history
    ADD CONSTRAINT product_status_history_pk
        PRIMARY KEY ("retailerId",
                     "coreProductId",
                     load_date);

CREATE UNIQUE INDEX product_status_history_productid_uindex
    ON staging.product_status_history ("productId");

CREATE TABLE staging."productStatuses" AS
SELECT "productStatuses".id,
       "productId",
       product_status_history.status,
       "productStatuses".screenshot,
       "productStatuses"."createdAt",
       "productStatuses"."updatedAt",
       "productStatuses".load_id
FROM staging.product_status_history
         LEFT OUTER JOIN public."productStatuses" USING ("productId");

ALTER TABLE public."productStatuses"
    RENAME TO "productStatuses-bck";
ALTER TABLE staging."productStatuses"
    SET SCHEMA public;

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