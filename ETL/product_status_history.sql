SELECT *
FROM staging.product_status
WHERE "sourceId" = '250411816';

SELECT *
FROM staging.products_last
WHERE "sourceId" = '250411816';

ALTER TABLE staging.product_status
    ALTER COLUMN date TYPE date USING date::date;

CREATE TABLE staging.retailer_products AS
WITH ret_prod AS (SELECT "retailerId",
                         "coreProductId",
                         date::date,
                         "coreRetailerId"
                  FROM "coreRetailerDates"
                           INNER JOIN "coreRetailers"
                                      ON ("coreRetailers".id = "coreRetailerDates"."coreRetailerId")
                           INNER JOIN dates ON (dates.id = "coreRetailerDates"."dateId"))
SELECT *
FROM ret_prod
ORDER BY 1, 2, 3;

ALTER TABLE staging.retailer_products
    ADD CONSTRAINT ret_prod_pk
        PRIMARY KEY ("retailerId",
                     "coreProductId",
                     date);
--WHERE "coreRetailerId" = 651096;


SELECT *
FROM "coreRetailers"
WHERE id = 651096;

SET WORK_MEM = '16GB';
SHOW WORK_MEM;
CREATE TABLE staging.product_status_history AS
WITH retailer_products AS (SELECT *,
                                  LAG(date) OVER (PARTITION BY "retailerId",
                                      "coreProductId" ORDER BY date) AS prev_date,
                                  ROW_NUMBER() OVER (PARTITION BY "retailerId",
                                      "coreProductId" ORDER BY date) AS rownum
                           FROM staging.retailer_products),
     status_base AS (SELECT *
                     FROM retailer_products
                              CROSS JOIN LATERAL (SELECT CASE
                                                             WHEN prev_date IS NULL THEN 'Newly'
                                                             WHEN prev_date = date - '1 day'::interval THEN 'Listed'
                                                             ELSE 'Re-listed'
                                                             END AS status
                         ) AS lat),
     product_status AS (SELECT "retailerId", "coreProductId", date, "coreRetailerId", status
                        FROM status_base
                        UNION ALL
                        SELECT "retailerId",
                               "coreProductId",
                               (prev_date + '1 day'::interval)::date AS date,
                               "coreRetailerId",
                               'De-listed'                           AS status
                        FROM status_base
                        WHERE status = 'Re-listed')
SELECT *
FROM product_status
--WHERE "retailerId" = 972
--  AND "coreProductId" = 372493
ORDER BY date;