DROP TABLE IF EXISTS staging.product_status;
CREATE TABLE staging.product_status AS
WITH retailer_latest_load AS (SELECT "retailerId", MAX(date) AS date
                              FROM products
                              GROUP BY 1),
     past_product_records AS (SELECT "retailerId",
                                     "sourceId",
                                     id                                                                AS "productId",
                                     date,
                                     LAG(date)
                                     OVER (PARTITION BY "retailerId", "sourceId" ORDER BY "date" DESC) AS prev_date,
                                     ROW_NUMBER()
                                     OVER (PARTITION BY "retailerId", "sourceId" ORDER BY "date" DESC) AS rownum
                              FROM products),
     latest AS (SELECT "retailerId", "sourceId", "productId", date, prev_date
                FROM past_product_records
                WHERE rownum = 1)
SELECT "retailerId",
       "sourceId",
       latest."productId",
       CASE
           WHEN lat.status = 'De-listead' THEN (latest.date + '1 day'::interval)::date
           ELSE
               latest.date END AS date,
       lat.status
FROM latest
         INNER JOIN retailer_latest_load USING ("retailerId")
         CROSS JOIN LATERAL (SELECT CASE
                                        WHEN latest.date < retailer_latest_load.date THEN 'De-listead'
                                        WHEN prev_date IS NULL THEN 'Newly'
                                        WHEN prev_date < latest.date - '1 day'::interval THEN 'Re-Listed'
                                        ELSE 'Listed'
                                        END AS status) AS lat;

ALTER TABLE staging.product_status
    ADD CONSTRAINT product_status_pk
        PRIMARY KEY ("retailerId", "sourceId");

