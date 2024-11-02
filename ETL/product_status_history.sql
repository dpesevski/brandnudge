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

CREATE INDEX products_retailerId_coreProductId_date_index
    ON products ("retailerId", "coreProductId", date);

/*  solution "A", using table public.products */
CREATE TABLE staging.retailer_product_load AS
WITH load AS (SELECT "retailerId",
                     "coreProductId",
                     ROW_NUMBER() OVER (PARTITION BY "retailerId", "coreProductId" ORDER BY date DESC) AS load_id,
                     date::date                                                                        AS load_date
              FROM products)
SELECT *
FROM load
ORDER BY 1, 2, 3;

/*  solution "B", using table public.coreRetailerDates */
CREATE TABLE staging.retailer_product_load AS
WITH load AS (SELECT "retailerId",
                     "coreProductId",
                     ROW_NUMBER() OVER (PARTITION BY "retailerId", "coreProductId" ORDER BY date DESC) AS load_id,
                     date::date                                                                        AS load_date
              FROM "coreRetailerDates"
                       INNER JOIN "coreRetailers"
                                  ON ("coreRetailers".id = "coreRetailerDates"."coreRetailerId")
                       INNER JOIN dates ON (dates.id = "coreRetailerDates"."dateId"))
SELECT *
FROM load
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