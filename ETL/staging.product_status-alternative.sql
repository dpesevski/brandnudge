SET WORK_MEM = '32GB';
SHOW WORK_MEM;

DROP TABLE IF EXISTS staging.product_status;
CREATE TABLE staging.product_status AS
WITH product AS (SELECT "retailerId",
                        "coreProductId",
                        id                                                                           AS "productId",
                        "dateId",
                        date,
                        ROW_NUMBER() OVER (PARTITION BY "retailerId", "sourceId" ORDER BY date DESC) AS rownum
                 FROM products),
     product_latest AS (WITH prev_prod AS (SELECT "retailerId",
                                                  "coreProductId",
                                                  date AS prev_date
                                           FROM product
                                           WHERE rownum = 2)

                        SELECT *
                        FROM product
                                 LEFT OUTER JOIN prev_prod USING ("retailerId", "coreProductId")
                        WHERE rownum = 1),
     retailer_latest AS (SELECT "retailerId",
                                MAX(date) AS last_load_date
                         FROM product_latest
                         GROUP BY "retailerId")
SELECT "retailerId",
       "coreProductId",
       "productId",
       "dateId",
       prev_date,
       CASE
           WHEN lat.status = 'De-listead' THEN (latest.date + '1 day'::interval)::date
           ELSE
               latest.date END AS date,
       lat.status
FROM product_latest latest
         INNER JOIN retailer_latest AS retailer_latest_load USING ("retailerId")
         CROSS JOIN LATERAL (SELECT CASE
                                        WHEN latest.date < retailer_latest_load.last_load_date THEN 'De-listead'
                                        WHEN prev_date IS NULL THEN 'Newly'
                                        WHEN prev_date < latest.date - '1 day'::interval THEN 'Re-Listed'
                                        ELSE 'Listed'
                                        END AS status) AS lat;

ALTER TABLE staging.product_status
    ADD CONSTRAINT product_status_pk
        PRIMARY KEY ("retailerId", "coreProductId");

