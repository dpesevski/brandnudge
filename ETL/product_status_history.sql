/*
SET WORK_MEM = '4GB';
SET max_parallel_workers_per_gather = 4;

CREATE INDEX products_retailerId_coreProductId_date_index
    ON products ("retailerId", "coreProductId", date);
*/
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
         INNER JOIN public."productStatuses" USING ("productId");

ALTER TABLE "productStatuses"
    ALTER COLUMN id DROP DEFAULT;

ALTER TABLE staging."productStatuses"
    ALTER COLUMN id SET DEFAULT NEXTVAL('"productStatuses_id_seq"'::regclass);

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
